#!/bin/bash
# =============================================================================
# deploy-loki.sh
# Full Loki Monitoring Stack Deployment for RKE2 v1.28.9
# 11 Nodes | 15-20 Microservices | Monolithic Mode
#
# Usage:
#   chmod +x deploy-loki.sh
#   ./deploy-loki.sh
#
# Pre-requisites:
#   - kubectl configured and connected to your RKE2 cluster
#   - helm v3 installed
#   - Files in same directory:
#       loki-values.yaml
#       grafana-values.yaml
#       alloy-values.yaml
#       istio-addons-values.yaml
#
# Chart download:
#   Loki 6.55.0 is no longer published on grafana/helm-charts (404). The
#   script pulls grafana-community/loki and caches .tgz files under .charts/.
#   GitHub release-asset CDN timeouts are retried via OCI (ghcr.io) and curl.
#   To skip downloads, place the tarballs in CHART_CACHE_DIR (default: .charts).
# =============================================================================

set -e   # Exit on any error

# =============================================================================
# LOGGING HELPERS  (must be defined before first use)
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'   # No Color

info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# =============================================================================
# CONFIGURATION — Edit these values before running
# =============================================================================
NAMESPACE="loki-monitoring"
LOKI_CHART_VERSION="6.55.0"
GRAFANA_CHART_VERSION="11.3.2"
ALLOY_CHART_VERSION="1.6.2"
ISTIO_ADDONS_CHART_VERSION="0.0.1-develop"
CHART_CACHE_DIR="${CHART_CACHE_DIR:-$SCRIPT_DIR/.charts}"
HELM_WAIT_TIMEOUT="${HELM_WAIT_TIMEOUT:-10m}"

# Chart sources. Loki OSS left grafana/helm-charts after 6.55.0; use the community fork.
LOKI_HELM_REF="grafana-community/loki"
LOKI_OCI_REF="oci://ghcr.io/grafana-community/helm-charts/loki"
LOKI_CHART_URL="https://github.com/grafana-community/helm-charts/releases/download/loki-${LOKI_CHART_VERSION}/loki-${LOKI_CHART_VERSION}.tgz"

GRAFANA_HELM_REF="grafana-community/grafana"
GRAFANA_OCI_REF="oci://ghcr.io/grafana-community/helm-charts/grafana"
GRAFANA_CHART_URL="https://github.com/grafana-community/helm-charts/releases/download/grafana-${GRAFANA_CHART_VERSION}/grafana-${GRAFANA_CHART_VERSION}.tgz"

ALLOY_HELM_REF="grafana/alloy"
ALLOY_OCI_REF=""
ALLOY_CHART_URL="https://github.com/grafana/helm-charts/releases/download/alloy-${ALLOY_CHART_VERSION}/alloy-${ALLOY_CHART_VERSION}.tgz"

ISTIO_ADDONS_HELM_REF="mosip/istio-addons"
ISTIO_ADDONS_OCI_REF=""
ISTIO_ADDONS_CHART_URL="https://mosip.github.io/mosip-helm/istio-addons-${ISTIO_ADDONS_CHART_VERSION}.tgz"

# =============================================================================
# CHART DOWNLOAD HELPERS
# Helm's HTTP client times out after ~120s waiting for GitHub release-asset
# headers (release-assets.githubusercontent.com). Pull to a local .tgz first
# via OCI / curl (5 minute timeout, retries), then install from the file.
# =============================================================================
CURL_RETRY_ARGS=(--retry 5 --retry-delay 4 --connect-timeout 30 --max-time 300)
if curl --help 2>/dev/null | grep -q -- '--retry-all-errors'; then
  CURL_RETRY_ARGS+=(--retry-all-errors)
fi

chart_tarball_ok() {
  local file="$1"
  [ -s "$file" ] && tar -tzf "$file" >/dev/null 2>&1
}

helm_pull_to() {
  local ref="$1" version="$2" dest="$3"
  local tmpdir pulled
  command -v helm >/dev/null 2>&1 || return 1
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/helm-pull.XXXXXX")"
  if helm pull "$ref" --version "$version" --destination "$tmpdir"; then
    pulled="$(find "$tmpdir" -maxdepth 1 -name '*.tgz' | head -n 1)"
    if [ -n "$pulled" ] && chart_tarball_ok "$pulled"; then
      mv "$pulled" "$dest"
      rm -rf "$tmpdir"
      return 0
    fi
  fi
  rm -rf "$tmpdir"
  return 1
}

curl_download_to() {
  local url="$1" dest="$2"
  command -v curl >/dev/null 2>&1 || return 1
  rm -f "$dest"
  curl -fL "${CURL_RETRY_ARGS[@]}" -o "$dest" "$url" && chart_tarball_ok "$dest"
}

# fetch_chart DEST_VAR NAME VERSION HELM_REF OCI_REF URL
fetch_chart() {
  local dest_var="$1" name="$2" version="$3" helm_ref="$4" oci_ref="$5" url="$6"
  local dest="$CHART_CACHE_DIR/${name}-${version}.tgz"
  local attempt

  mkdir -p "$CHART_CACHE_DIR"

  if chart_tarball_ok "$dest"; then
    success "Using cached chart: $dest"
    printf -v "$dest_var" '%s' "$dest"
    return 0
  fi
  rm -f "$dest"

  info "Fetching ${name} chart ${version}..."

  if [ -n "$oci_ref" ]; then
    for attempt in 1 2 3; do
      info "  OCI attempt ${attempt}/3: $oci_ref"
      if helm_pull_to "$oci_ref" "$version" "$dest"; then
        success "Pulled ${name} from OCI"
        printf -v "$dest_var" '%s' "$dest"
        return 0
      fi
      warn "  OCI pull failed"
      sleep $((attempt * 4))
    done
  fi

  if [ -n "$url" ]; then
    info "  Direct download: $url"
    if curl_download_to "$url" "$dest"; then
      success "Downloaded ${name} via curl"
      printf -v "$dest_var" '%s' "$dest"
      return 0
    fi
    warn "  Direct download failed"
    rm -f "$dest"
  fi

  if [ -n "$helm_ref" ]; then
    for attempt in 1 2 3; do
      info "  helm pull attempt ${attempt}/3: $helm_ref"
      if helm_pull_to "$helm_ref" "$version" "$dest"; then
        success "Pulled ${name} from Helm repo"
        printf -v "$dest_var" '%s' "$dest"
        return 0
      fi
      warn "  helm pull failed (GitHub release assets often time out)"
      sleep $((attempt * 4))
    done
  fi

  error "Failed to download ${name} ${version}. Helm timed out talking to GitHub release assets.
  Workaround: on a machine with GitHub access, download the chart and copy it to:
    $dest
  Then re-run ./deploy-loki.sh
  Example:
    curl -fL -o $dest $url"
}

helm_upgrade_install() {
  local release="$1" chart_file="$2"
  shift 2
  helm upgrade --install "$release" "$chart_file" \
    --namespace "$NAMESPACE" \
    --wait --timeout "$HELM_WAIT_TIMEOUT" \
    "$@"
}

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
info "Running pre-flight checks..."

command -v kubectl >/dev/null 2>&1 || error "kubectl not found. Please install kubectl."
command -v helm    >/dev/null 2>&1 || error "helm not found. Please install helm v3."
command -v curl    >/dev/null 2>&1 || error "curl not found. Please install curl (used to download Helm charts)."

# Check cluster connectivity
kubectl cluster-info >/dev/null 2>&1 || error "Cannot connect to Kubernetes cluster. Check kubeconfig."
success "Cluster connectivity verified"

# Check required files exist (only files this script actually uses)
for f in loki-values.yaml grafana-values.yaml alloy-values.yaml istio-addons-values.yaml; do
  [ -f "$f" ] || error "Required file not found: $f. Run this script from the deployment directory."
done
success "All required YAML files found"

if grep -q 'grafana.sandbox.xyz.net' grafana-values.yaml istio-addons-values.yaml; then
  warn "Grafana host is still grafana.sandbox.xyz.net"
  warn "Update grafana-values.yaml (grafana.ini.server.domain / root_url) and istio-addons-values.yaml (istio.host) to this environment's hostname before exposing Grafana."
fi

# =============================================================================
# STEP 1: Create Namespace
# =============================================================================
info "Step 1: Creating namespace: $NAMESPACE"
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  warn "Namespace $NAMESPACE already exists — skipping creation"
else
  kubectl create namespace "$NAMESPACE"
fi
success "Namespace ready: $NAMESPACE"

# =============================================================================
# STEP 2: Add Helm Repos
# =============================================================================
info "Step 2: Adding Helm repositories..."
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo add grafana-community https://grafana-community.github.io/helm-charts 2>/dev/null || true
helm repo add mosip https://mosip.github.io/mosip-helm 2>/dev/null || true
if helm repo update; then
  success "Helm repos updated"
else
  warn "helm repo update failed — will install from OCI / direct chart downloads"
fi

# =============================================================================
# STEP 3: Deploy Loki
# =============================================================================
info "Step 3: Deploying Loki (chart: $LOKI_CHART_VERSION)..."
LOKI_CHART_FILE=""
fetch_chart LOKI_CHART_FILE loki "$LOKI_CHART_VERSION" \
  "$LOKI_HELM_REF" "$LOKI_OCI_REF" "$LOKI_CHART_URL"

if helm status loki -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Loki already installed — upgrading..."
fi
helm_upgrade_install loki "$LOKI_CHART_FILE" -f loki-values.yaml
success "Loki deployed successfully"

# =============================================================================
# STEP 4: Deploy Grafana
# =============================================================================
info "Step 4: Deploying Grafana (chart: $GRAFANA_CHART_VERSION)..."

# Read from environment or prompt securely
if [ -z "$GRAFANA_PASSWORD" ]; then
  read -s -p "Enter Grafana admin password: " GRAFANA_PASSWORD
  echo
fi

# Optional: basic validation
if [ -z "$GRAFANA_PASSWORD" ]; then
  echo "ERROR: Grafana password cannot be empty"
  exit 1
fi

GRAFANA_CHART_FILE=""
fetch_chart GRAFANA_CHART_FILE grafana "$GRAFANA_CHART_VERSION" \
  "$GRAFANA_HELM_REF" "$GRAFANA_OCI_REF" "$GRAFANA_CHART_URL"

if helm status grafana -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Grafana already installed — upgrading..."
fi
helm_upgrade_install grafana "$GRAFANA_CHART_FILE" \
  -f grafana-values.yaml \
  --set adminPassword="$GRAFANA_PASSWORD"
success "Grafana deployed successfully"

# Wait a few seconds for status to update
sleep 10

# =============================================================================
# STEP 5: Deploy Alloy
# =============================================================================
info "Step 5: Deploying Grafana Alloy..."
ALLOY_CHART_FILE=""
fetch_chart ALLOY_CHART_FILE alloy "$ALLOY_CHART_VERSION" \
  "$ALLOY_HELM_REF" "$ALLOY_OCI_REF" "$ALLOY_CHART_URL"

if helm status alloy -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Alloy already installed — upgrading..."
fi
helm_upgrade_install alloy "$ALLOY_CHART_FILE" -f alloy-values.yaml
success "Alloy deployed successfully"

# ===========================================================================
# STEP 6: Deploy Istio Addons
# ==========================================================================

info "Step 6: Deploying Istio Addons..."
ISTIO_ADDONS_CHART_FILE=""
fetch_chart ISTIO_ADDONS_CHART_FILE istio-addons "$ISTIO_ADDONS_CHART_VERSION" \
  "$ISTIO_ADDONS_HELM_REF" "$ISTIO_ADDONS_OCI_REF" "$ISTIO_ADDONS_CHART_URL"

if helm status istio-addons -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Istio-Addons already installed — upgrading..."
fi
helm_upgrade_install istio-addons "$ISTIO_ADDONS_CHART_FILE" \
  -f istio-addons-values.yaml
success "Istio Addons deployed successfully"

# =============================================================================
# STEP 7: Import Custom Dashboards
# =============================================================================
info "Step 7: Importing custom Grafana dashboards..."

DASHBOARD_DIR="dashboards"

# Wait for Grafana so the sidecar is actually running before we create ConfigMaps
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=grafana \
  -n "$NAMESPACE" \
  --timeout=120s >/dev/null \
  || warn "Grafana not ready yet — dashboards will load when sidecar starts"

if [ ! -d "$DASHBOARD_DIR" ]; then
  warn "Directory '$DASHBOARD_DIR' not found in $(pwd) — skipping dashboard import"
else
  shopt -s nullglob
  dashboard_files=( "$DASHBOARD_DIR"/*.json )
  shopt -u nullglob

  if [ ${#dashboard_files[@]} -eq 0 ]; then
    warn "No JSON files found in $DASHBOARD_DIR/ — skipping"
  else
    for f in "${dashboard_files[@]}"; do
      # Derive a valid ConfigMap name from the filename
      cm_name=$(basename "$f" .json | tr '[:upper:]_.' '[:lower:]--' | sed 's/[^a-z0-9-]//g')
      info "  → $f as ConfigMap '$cm_name'"

      kubectl create configmap "$cm_name" \
        --namespace "$NAMESPACE" \
        --from-file="$f" \
        --dry-run=client -o yaml \
        | kubectl label --local -f - grafana_dashboard=1 -o yaml \
        | kubectl apply -f -
    done
    success "Submitted ${#dashboard_files[@]} dashboard(s) — sidecar will provision them within ~10s"
  fi
fi

# =============================================================================
# STEP 8: Verify Deployment
# =============================================================================
info "Step 8: Verifying deployment..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Pods in $NAMESPACE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Services in $NAMESPACE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get svc -n "$NAMESPACE"

# =============================================================================
# STEP 9: Print Access Info
# =============================================================================
echo ""
echo "  Access Grafana:"
echo "  ─────────────────────────────────────────────────────"
echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo "  Open: https://grafana.sandbox.xyz.net (update host in grafana-values.yaml / istio-addons-values.yaml)"
echo "  User: admin"
echo "  NOTE: The Grafana Dashboard will ask for user password, Please provide the grafana password that was setup while installing"
echo ""
echo "  Loki API:"
echo "  ─────────────────────────────────────────────────────"
echo "  kubectl port-forward -n $NAMESPACE svc/loki 3100:3100"
echo "  Health: http://localhost:3100/ready"
echo ""
echo "  Test LogQL Queries in Grafana Explore:"
echo "  ─────────────────────────────────────────────────────"
echo "  {cluster=\"rke2\"}"
echo "  {namespace=\"default\"} |= \"error\""
echo "  {cluster=\"rke2\"} | json"
echo ""

# =============================================================================
# STEP 10: Quick Health Check
# =============================================================================
info "Running quick Loki health check..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=loki \
  -n "$NAMESPACE" \
  --timeout=180s && success "Loki pod is Ready ✅" || warn "Loki pod not ready yet — check: kubectl get pods -n $NAMESPACE"

info "Running quick Grafana health check..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=grafana \
  -n "$NAMESPACE" \
  --timeout=180s && success "Grafana pod is Ready ✅" || warn "Grafana pod not ready yet — check: kubectl get pods -n $NAMESPACE"
