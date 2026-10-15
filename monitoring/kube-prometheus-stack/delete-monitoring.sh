#!/bin/bash
# =============================================================================
# delete-monitoring.sh
# Removes the standalone Monitoring + Alerting stack deployed by
# deploy-monitoring.sh (kube-prometheus-stack).
#
# Removes: the Helm release, the alertmanager-smtp secret, and (optionally)
#          the prometheus-operator CRDs and the namespace.
#
# Usage:
#   chmod +x delete-monitoring.sh
#   ./delete-monitoring.sh                 # interactive, keeps CRDs + namespace
#   ./delete-monitoring.sh --crds          # also delete prometheus-operator CRDs
#   ./delete-monitoring.sh --namespace     # also delete the namespace
#   ./delete-monitoring.sh --all           # release + secret + CRDs + namespace
#   ./delete-monitoring.sh --yes           # skip confirmation prompts
#
# WARNING:
#   --crds removes CLUSTER-SCOPED CRDs. If ANOTHER prometheus-operator-based
#   stack shares them (e.g. rancher-monitoring), deleting CRDs will break it
#   and delete all ServiceMonitors/PrometheusRules cluster-wide. Only use
#   --crds when this is the only prometheus-operator stack on the cluster.
# =============================================================================

set -e

# ── Logging helpers ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; exit 1; }

# =============================================================================
# CONFIGURATION — must match deploy-monitoring.sh
# =============================================================================
NAMESPACE="monitoring"
RELEASE="monitoring"
PROM_OPERATOR_CRD_VERSION="v0.93.1"   # only used to know which CRD names to remove

# ── Flags ──
DELETE_CRDS=false
DELETE_NAMESPACE=false
ASSUME_YES=false
for arg in "$@"; do
  case "$arg" in
    --crds)      DELETE_CRDS=true ;;
    --namespace) DELETE_NAMESPACE=true ;;
    --all)       DELETE_CRDS=true; DELETE_NAMESPACE=true ;;
    --yes|-y)    ASSUME_YES=true ;;
    *) error "Unknown option: $arg (use --crds, --namespace, --all, --yes)" ;;
  esac
done

confirm() {
  # $1 = prompt. Returns 0 to proceed, 1 to skip.
  $ASSUME_YES && return 0
  read -r -p "$1 [y/N] " ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

# =============================================================================
# PRE-FLIGHT
# =============================================================================
info "========== Monitoring Stack Teardown =========="
command -v kubectl >/dev/null 2>&1 || error "kubectl not found."
command -v helm    >/dev/null 2>&1 || error "helm not found (need v3)."
kubectl cluster-info >/dev/null 2>&1 || error "Cannot reach cluster. Check kubeconfig."
success "kubectl + helm present, cluster reachable"

echo ""
warn "About to remove the monitoring stack from namespace '$NAMESPACE':"
echo "    - Helm release:     $RELEASE"
echo "    - Secret:           alertmanager-smtp"
$DELETE_CRDS      && echo "    - prometheus-operator CRDs (CLUSTER-SCOPED — see warning in header)"
$DELETE_NAMESPACE && echo "    - Namespace:        $NAMESPACE"
echo ""
if ! confirm "Proceed?"; then
  info "Aborted. Nothing was removed."
  exit 0
fi

# =============================================================================
# STEP 1: Uninstall the Helm release
# =============================================================================
info "Step 1: Uninstalling Helm release '$RELEASE'..."
if helm status "$RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
  helm uninstall "$RELEASE" -n "$NAMESPACE"
  success "  release '$RELEASE' uninstalled"
else
  warn "  release '$RELEASE' not found in '$NAMESPACE' — skipping"
fi

# =============================================================================
# STEP 2: Remove the SMTP secret
# =============================================================================
info "Step 2: Removing alertmanager-smtp secret..."
if kubectl -n "$NAMESPACE" get secret alertmanager-smtp >/dev/null 2>&1; then
  kubectl -n "$NAMESPACE" delete secret alertmanager-smtp
  success "  secret alertmanager-smtp deleted"
else
  warn "  secret alertmanager-smtp not found — skipping"
fi

# =============================================================================
# STEP 3: Clean up leftover resources Helm may not remove
# (PVCs from Prometheus/Alertmanager StatefulSets are retained by default)
# =============================================================================
info "Step 3: Checking for leftover PVCs in '$NAMESPACE'..."
LEFTOVER_PVCS=$(kubectl -n "$NAMESPACE" get pvc -o name 2>/dev/null || true)
if [ -n "$LEFTOVER_PVCS" ]; then
  warn "  Found PVCs (retained by Helm on uninstall):"
  kubectl -n "$NAMESPACE" get pvc
  if confirm "  Delete these PVCs? (destroys Prometheus/Alertmanager data)"; then
    echo "$LEFTOVER_PVCS" | xargs -r kubectl -n "$NAMESPACE" delete
    success "  PVCs deleted"
  else
    warn "  PVCs kept. Data preserved; delete manually later if not needed."
  fi
else
  info "  no PVCs found"
fi

# =============================================================================
# STEP 4 (optional): Delete prometheus-operator CRDs
# =============================================================================
if $DELETE_CRDS; then
  warn "Step 4: Deleting prometheus-operator CRDs (cluster-scoped)..."
  warn "  This breaks ANY other prometheus-operator stack on the cluster and"
  warn "  removes all ServiceMonitors/PrometheusRules cluster-wide."
  if confirm "  Are you SURE this is the only prometheus-operator stack?"; then
    for crd in alertmanagers alertmanagerconfigs prometheuses prometheusagents \
               scrapeconfigs podmonitors probes prometheusrules thanosrulers servicemonitors; do
      FULL="${crd}.monitoring.coreos.com"
      if kubectl get crd "$FULL" >/dev/null 2>&1; then
        kubectl delete crd "$FULL" && info "  deleted CRD: $FULL"
      fi
    done
    success "  prometheus-operator CRDs deleted"
  else
    warn "  CRD deletion skipped."
  fi
else
  info "Step 4: Keeping prometheus-operator CRDs (use --crds to remove)."
fi

# =============================================================================
# STEP 5 (optional): Delete the namespace
# =============================================================================
if $DELETE_NAMESPACE; then
  info "Step 5: Deleting namespace '$NAMESPACE'..."
  if kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
    kubectl delete namespace "$NAMESPACE"
    success "  namespace '$NAMESPACE' deleted"
  else
    warn "  namespace '$NAMESPACE' not found — skipping"
  fi
else
  info "Step 5: Keeping namespace '$NAMESPACE' (use --namespace to remove)."
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo "==========================================="
echo " Monitoring stack teardown complete"
echo "-------------------------------------------"
echo " Removed: Helm release '$RELEASE', alertmanager-smtp secret"
$DELETE_CRDS      && echo "          + prometheus-operator CRDs"
$DELETE_NAMESPACE && echo "          + namespace '$NAMESPACE'"
echo ""
echo " Verify nothing remains:"
echo "   kubectl get all -n $NAMESPACE"
echo "   helm list -n $NAMESPACE"
echo "==========================================="
echo ""
echo " NOTE: node-level config (bind-address in /etc/rancher/rke2/config.yaml)"
echo " and AWS security-group rules are NOT touched by this script — they are"
echo " infra-level (see PREREQUISITES.md). Remove them separately if desired."
echo ""