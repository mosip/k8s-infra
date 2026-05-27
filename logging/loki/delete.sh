#!/bin/bash
# =============================================================================
# delete.sh — Uninstall Loki monitoring stack
# Mirrors install.sh: same logging, reverse-order helm uninstall,
# and cleanup of resources install.sh creates outside of helm releases
#
# Usage:
#   chmod +x delete.sh
#   ./delete.sh
# =============================================================================

set -e

# =============================================================================
# LOGGING HELPERS
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; exit 1; }

# =============================================================================
# CONFIGURATION — must match install.sh
# =============================================================================
NAMESPACE="loki-monitoring"

# Helm releases in REVERSE order of install (uninstall dependents first)
RELEASES=(istio-addons alloy grafana loki)

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
info "Running pre-flight checks..."

command -v kubectl >/dev/null 2>&1 || error "kubectl not found. Please install kubectl."
command -v helm    >/dev/null 2>&1 || error "helm not found. Please install helm v3."

kubectl cluster-info >/dev/null 2>&1 || error "Cannot connect to Kubernetes cluster. Check kubeconfig."
success "Cluster connectivity verified"

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  warn "Namespace '$NAMESPACE' does not exist — nothing to uninstall"
  exit 0
fi

# =============================================================================
# STEP 1: Delete custom dashboard ConfigMaps
# =============================================================================
info "Step 1: Deleting custom dashboard ConfigMaps..."
cm_count=$(kubectl get cm -n "$NAMESPACE" -l grafana_dashboard=1 -o name 2>/dev/null | wc -l)
if [ "$cm_count" -eq 0 ]; then
  warn "No dashboard ConfigMaps found — skipping"
else
  kubectl delete cm -n "$NAMESPACE" -l grafana_dashboard=1
  success "Deleted $cm_count dashboard ConfigMap(s)"
fi

# =============================================================================
# STEP 2: Uninstall Helm releases (reverse of install order)
# =============================================================================
info "Step 2: Uninstalling Helm releases in reverse order..."

for release in "${RELEASES[@]}"; do
  if helm status "$release" -n "$NAMESPACE" >/dev/null 2>&1; then
    info "  → Uninstalling $release..."
    if helm uninstall "$release" -n "$NAMESPACE" --wait --timeout 3m; then
      success "  $release uninstalled"
    else
      warn "  $release uninstall failed — continuing"
    fi
  else
    warn "  $release not installed — skipping"
  fi
done

# =============================================================================
# STEP 3: Delete PVCs (helm doesn't remove StatefulSet PVCs)
# =============================================================================
info "Step 3: Deleting PersistentVolumeClaims..."
pvc_count=$(kubectl get pvc -n "$NAMESPACE" -o name 2>/dev/null | wc -l)
if [ "$pvc_count" -eq 0 ]; then
  warn "No PVCs found — skipping"
else
  kubectl delete pvc -n "$NAMESPACE" --all --timeout=60s \
    || warn "Some PVCs lingered — namespace deletion will sweep them"
  success "PVCs deleted"
fi

# =============================================================================
# STEP 4: Delete the namespace (catches anything left over)
# =============================================================================
info "Step 4: Deleting namespace '$NAMESPACE'..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found --timeout=120s
success "Namespace deleted"

# =============================================================================
# DONE
# =============================================================================
echo ""
success "Loki monitoring stack uninstalled"
echo ""
echo "  ─────────────────────────────────────────────────────"
echo "  Note: PersistentVolumes may still exist if your StorageClass"
echo "  uses reclaimPolicy=Retain (common for NFS). Check with:"
echo "    kubectl get pv | grep -E 'loki|grafana|$NAMESPACE'"
echo ""
echo "  If you see Released PVs you want gone, delete them explicitly:"
echo "    kubectl delete pv <pv-name>"
echo "  …and clean the NFS backing directory if your CSI driver doesn't."
echo "  ─────────────────────────────────────────────────────"
echo ""
