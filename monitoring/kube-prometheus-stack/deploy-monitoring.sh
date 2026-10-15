#!/bin/bash
# =============================================================================
# deploy-monitoring.sh
# Standalone Monitoring + Alerting stack for RKE2 (kube-prometheus-stack).
#
# Deploys: Prometheus, Alertmanager (email alerting), node-exporter,
#          kube-state-metrics, control-plane component scraping.
# Grafana is NOT deployed here — it lives in the standalone Loki stack
#   (deploy-loki.sh); Prometheus is added there as a datasource.
#
# Usage:
#   chmod +x deploy-monitoring.sh
#   ./deploy-monitoring.sh
#
# Pre-requisites (see PREREQUISITES.md — MUST be done first):
#   - rancher-monitoring fully removed (operator + helm release) incase previously deployed.
#   - kubectl + helm v3 installed, cluster reachable
#   - SMTP credentials available for the alertmanager-smtp secret
#   - values-monitoring.yaml in the same directory.
# =============================================================================

set -e

# ── Logging helpers ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; exit 1; }

# =============================================================================
# CONFIGURATION — edit before running
# =============================================================================
NAMESPACE="monitoring"
RELEASE="monitoring"
KPS_CHART_VERSION="88.6.2"
PROM_OPERATOR_CRD_VERSION="v0.93.1"
VALUES_FILE="values-monitoring.yaml"

# SMTP secret inputs — leave blank to be prompted / read from env
SMTP_PASSWORD="${SMTP_PASSWORD:-}"

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
info "========== Monitoring Stack Deploy =========="
info "Running pre-flight checks..."

command -v kubectl >/dev/null 2>&1 || error "kubectl not found."
command -v helm    >/dev/null 2>&1 || error "helm not found (need v3)."
kubectl cluster-info >/dev/null 2>&1 || error "Cannot reach cluster. Check kubeconfig."
success "kubectl + helm present, cluster reachable"

[ -f "$VALUES_FILE" ] || error "$VALUES_FILE not found. Run from the deploy directory."
success "Values file found: $VALUES_FILE"

# Warn loudly if rancher-monitoring is still around (the recreate-loop cause)
if kubectl get ns cattle-monitoring-system >/dev/null 2>&1; then
  if kubectl -n cattle-monitoring-system get deploy 2>/dev/null | grep -qi operator; then
    warn "rancher-monitoring operator still present in cattle-monitoring-system."
    warn "This causes a two-operator reconcile loop. See PREREQUISITES.md step 1."
    warn "Remove it before continuing, or the Alertmanager pod will churn."
    read -r -p "Continue anyway? [y/N] " ans
    [ "$ans" = "y" ] || error "Aborting — remove rancher-monitoring first."
  fi
fi

# =============================================================================
# STEP 1: Helm repo
# =============================================================================
info "Step 1: Adding prometheus-community Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update >/dev/null
helm search repo prometheus-community/kube-prometheus-stack --version "$KPS_CHART_VERSION" \
  | grep -q "$KPS_CHART_VERSION" \
  || error "Chart version $KPS_CHART_VERSION not found. Run: helm search repo prometheus-community/kube-prometheus-stack --versions"
success "Chart kube-prometheus-stack $KPS_CHART_VERSION verified"

# =============================================================================
# STEP 2: Namespace
# =============================================================================
info "Step 2: Ensuring namespace $NAMESPACE..."
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
success "Namespace ready: $NAMESPACE"

# =============================================================================
# STEP 3: Upgrade prometheus-operator CRDs (server-side)
# Prevents the ".status.selector/.shards: field not declared in schema" loop
# when CRDs from a prior operator (e.g. rancher-monitoring) are present.
# =============================================================================
info "Step 3: Applying matching prometheus-operator CRDs ($PROM_OPERATOR_CRD_VERSION)..."
CRD_BASE="https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${PROM_OPERATOR_CRD_VERSION}/example/prometheus-operator-crd"
for crd in alertmanagers alertmanagerconfigs prometheuses prometheusagents \
           scrapeconfigs podmonitors probes prometheusrules thanosrulers servicemonitors; do
  kubectl apply --server-side --force-conflicts \
    -f "${CRD_BASE}/monitoring.coreos.com_${crd}.yaml" >/dev/null \
    && info "  applied CRD: $crd" \
    || warn "  could not apply CRD $crd (may be fine if network-restricted; verify manually)"
done
success "CRDs applied/upgraded server-side"

# =============================================================================
# STEP 4: SMTP secret for Alertmanager email
# =============================================================================
info "Step 4: Creating alertmanager-smtp secret..."
if kubectl -n "$NAMESPACE" get secret alertmanager-smtp >/dev/null 2>&1; then
  warn "  secret alertmanager-smtp already exists — leaving as-is."
  warn "  To rotate: kubectl -n $NAMESPACE delete secret alertmanager-smtp, then re-run."
else
  if [ -z "$SMTP_PASSWORD" ]; then
    read -r -s -p "Enter SMTP password (for Alertmanager email): " SMTP_PASSWORD; echo
  fi
  [ -n "$SMTP_PASSWORD" ] || error "SMTP password cannot be empty."
  kubectl -n "$NAMESPACE" create secret generic alertmanager-smtp \
    --from-literal=password="$SMTP_PASSWORD"
  success "  secret alertmanager-smtp created"
fi

# =============================================================================
# STEP 5: Install / upgrade the stack
# =============================================================================
info "Step 5: Deploying kube-prometheus-stack..."
if helm status "$RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "  release exists — upgrading..."
  ACTION=upgrade
else
  ACTION=install
fi
helm "$ACTION" "$RELEASE" prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" \
  --version "$KPS_CHART_VERSION" \
  -f "$VALUES_FILE" \
  --wait --timeout 10m
success "  stack ${ACTION}d"

# =============================================================================
# STEP 6: Verify
# =============================================================================
info "Step 6: Verifying deployment..."
echo ""
echo "━━━━━━━━━━ Pods in $NAMESPACE ━━━━━━━━━━"
kubectl get pods -n "$NAMESPACE"
echo ""

# Confirm the Alertmanager pod is stable (not in the recreate loop)
info "Checking Alertmanager pod stability (10s)..."
sleep 10
AM_POD="alertmanager-${RELEASE}-kube-prometheus-alertmanager-0"
R1=$(kubectl -n "$NAMESPACE" get statefulset "${RELEASE}-kube-prometheus-alertmanager" \
     -o jsonpath='{.metadata.generation}' 2>/dev/null || echo "?")
sleep 10
R2=$(kubectl -n "$NAMESPACE" get statefulset "${RELEASE}-kube-prometheus-alertmanager" \
     -o jsonpath='{.metadata.generation}' 2>/dev/null || echo "?")
if [ "$R1" = "$R2" ] && [ "$R1" != "?" ]; then
  success "  Alertmanager StatefulSet stable (generation $R1, not climbing)"
else
  warn "  Alertmanager generation changed ($R1 -> $R2) — possible reconcile loop."
  warn "  Check for leftover rancher-monitoring operator (PREREQUISITES.md step 1)."
fi

# =============================================================================
# STEP 7: Post-deploy guidance
# =============================================================================
echo ""
echo "==========================================="
echo " Monitoring stack deployed"
echo "-------------------------------------------"
echo " Prometheus : svc/${RELEASE}-kube-prometheus-prometheus:9090 (ns $NAMESPACE)"
echo " Alertmanager: svc/${RELEASE}-kube-prometheus-alertmanager:9093"
echo "==========================================="
echo ""
echo " NEXT STEPS (manual, one-time per environment):"
echo ""
echo " 1. Add Prometheus as a datasource in the standalone Loki Grafana:"
echo "      url: http://${RELEASE}-kube-prometheus-prometheus.${NAMESPACE}.svc.cluster.local:9090"
echo "    (set in that Grafana's values datasources block + helm upgrade)"
echo ""
echo " 2. Verify all node-exporter targets are UP:"
echo "      kubectl -n $NAMESPACE port-forward svc/${RELEASE}-kube-prometheus-prometheus 9090:9090"
echo "      open http://localhost:9090/targets"
echo "    If some nodes are DOWN -> check SG port 9100 (PREREQUISITES.md step 3)."
echo ""
echo " 3. Verify control-plane targets (etcd/scheduler/controller-manager) UP:"
echo "    If DOWN -> node config.yaml bind-address + SG ports (prereqs 2 & 3)."
echo ""
echo " 4. Test email alerting end-to-end:"
echo "      kubectl -n $NAMESPACE port-forward svc/${RELEASE}-kube-prometheus-alertmanager 9093:9093"
echo "      curl -XPOST http://localhost:9093/api/v2/alerts -H 'Content-Type: application/json' \\"
echo "        -d '[{\"labels\":{\"alertname\":\"EmailTest\",\"severity\":\"critical\",\"cluster\":\"<env>\"},"
echo "             \"annotations\":{\"summary\":\"Test\",\"description\":\"Verify email\"}}]'"
echo "    -> check the configured inbox."
echo ""
echo " Config check on failure:"
echo "   kubectl -n $NAMESPACE logs ${AM_POD} -c alertmanager --tail=30"
echo ""