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

# =============================================================================
# CONFIGURATION — Edit these values before running
# =============================================================================
NAMESPACE="loki-monitoring"
LOKI_CHART_VERSION="6.55.0"
GRAFANA_CHART_VERSION="11.3.2"
ALLOY_CHART_VERSION="1.6.2"
ISTIO_ADDONS_CHART_VERSION="0.0.1-develop"

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
info "Running pre-flight checks..."

command -v kubectl >/dev/null 2>&1 || error "kubectl not found. Please install kubectl."
command -v helm    >/dev/null 2>&1 || error "helm not found. Please install helm v3."

# Check cluster connectivity
kubectl cluster-info >/dev/null 2>&1 || error "Cannot connect to Kubernetes cluster. Check kubeconfig."
success "Cluster connectivity verified"

# Check required files exist (only files this script actually uses)
for f in loki-values.yaml grafana-values.yaml alloy-values.yaml istio-addons-values.yaml; do
  [ -f "$f" ] || error "Required file not found: $f. Run this script from the deployment directory."
done
success "All required YAML files found"

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
info "Step 2: Adding Grafana Helm repository..."
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo add grafana-community https://grafana-community.github.io/helm-charts 2>/dev/null || true
helm repo add mosip https://mosip.github.io/mosip-helm 2>/dev/null || true
helm repo update
success "Helm repos updated"

# Verify chart version is available
helm search repo grafana/loki --version "$LOKI_CHART_VERSION" | grep -q "$LOKI_CHART_VERSION" || \
  error "Loki chart version $LOKI_CHART_VERSION not found. Run: helm search repo grafana/loki --versions"
success "Loki chart version $LOKI_CHART_VERSION verified"

# =============================================================================
# STEP 3: Deploy Loki
# =============================================================================
info "Step 3: Deploying Loki (chart: $LOKI_CHART_VERSION)..."

if helm status loki -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Loki already installed — upgrading..."
  helm upgrade loki grafana/loki \
    --namespace "$NAMESPACE" \
    --version "$LOKI_CHART_VERSION" \
    -f loki-values.yaml \
    --wait --timeout 5m
else
  helm install loki grafana/loki \
    --namespace "$NAMESPACE" \
    --version "$LOKI_CHART_VERSION" \
    -f loki-values.yaml \
    --wait --timeout 5m
fi
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

# Verify the requested chart version is reachable in the community repo
helm search repo grafana-community/grafana --version "$GRAFANA_CHART_VERSION" \
  | grep -q "$GRAFANA_CHART_VERSION" \
  || error "Grafana chart version $GRAFANA_CHART_VERSION not found in grafana-community repo. Run: helm search repo grafana-community/grafana --versions"
success "Grafana chart version $GRAFANA_CHART_VERSION verified"

if helm status grafana -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Grafana already installed — upgrading..."
  helm upgrade grafana grafana-community/grafana \
    --namespace "$NAMESPACE" \
    --version "$GRAFANA_CHART_VERSION" \
    -f grafana-values.yaml \
    --set adminPassword="$GRAFANA_PASSWORD" \
    --wait --timeout 5m
else
  helm install grafana grafana-community/grafana \
    --namespace "$NAMESPACE" \
    --version "$GRAFANA_CHART_VERSION" \
    -f grafana-values.yaml \
    --set adminPassword="$GRAFANA_PASSWORD" \
    --wait --timeout 5m
fi
success "Grafana deployed successfully"

# Wait a few seconds for status to update
sleep 10

# =============================================================================
# STEP 5: Deploy Alloy
# =============================================================================
info "Step 5: Deploying Grafana Alloy..."

if helm status alloy -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Alloy already installed — upgrading..."
  helm upgrade alloy grafana/alloy \
    --namespace "$NAMESPACE" \
    --version "$ALLOY_CHART_VERSION" \
    -f alloy-values.yaml \
    --wait --timeout 5m
else
  helm install alloy grafana/alloy \
    --namespace "$NAMESPACE" \
    --version "$ALLOY_CHART_VERSION" \
    -f alloy-values.yaml \
    --wait --timeout 5m
fi
success "Alloy deployed successfully"

# ===========================================================================
# STEP 6: Deploy Istio Addons
# ==========================================================================

info "step 6: Deploying Istio Addons..."
if helm status istio-addons -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Istio-Addons already installed — upgrading..."
  helm upgrade istio-addons mosip/istio-addons \
    --namespace "$NAMESPACE" \
    --version "$ISTIO_ADDONS_CHART_VERSION" \
    -f istio-addons-values.yaml \
    --wait --timeout 2m
else
  helm install istio-addons mosip/istio-addons \
    --namespace "$NAMESPACE" \
    --version "$ISTIO_ADDONS_CHART_VERSION" \
    -f istio-addons-values.yaml \
    --wait --timeout 2m
fi
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
info "Step 7: Verifying deployment..."

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
echo "  Open: https://grafana.sandbox.xyz.net:3000"
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
  --timeout=120s && success "Loki pod is Ready ✅" || warn "Loki pod not ready yet — check: kubectl get pods -n $NAMESPACE"

info "Running quick Grafana health check..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=grafana \
  -n "$NAMESPACE" \
  --timeout=120s && success "Grafana pod is Ready ✅" || warn "Grafana pod not ready yet — check: kubectl get pods -n $NAMESPACE"
