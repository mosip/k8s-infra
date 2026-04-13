#!/bin/bash
# =============================================================================
# delete-loki.sh
# Full Loki Monitoring Stack Removal for RKE2 v1.28.9
# Removes: Alloy, Grafana, Loki, and the loki-monitoring namespace
#
# Usage:
#   chmod +x delete-loki.sh
#   ./delete-loki.sh
#
# ⚠️  WARNING: This will permanently delete all Loki data and Grafana dashboards!
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION — Must match deploy-loki.sh values
# =============================================================================
NAMESPACE="loki-monitoring"

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
info "Running pre-flight checks..."

command -v kubectl >/dev/null 2>&1 || error "kubectl not found. Please install kubectl."
command -v helm    >/dev/null 2>&1 || error "helm not found. Please install helm v3."

kubectl cluster-info >/dev/null 2>&1 || error "Cannot connect to Kubernetes cluster. Check kubeconfig."
success "Cluster connectivity verified"

# =============================================================================
# CONFIRMATION PROMPT
# =============================================================================
echo "  This script will permanently delete:"
echo "    • Helm release: alloy        (namespace: $NAMESPACE)"
echo "    • Helm release: grafana      (namespace: $NAMESPACE)"
echo "    • Helm release: loki         (namespace: $NAMESPACE)"
echo "    • Namespace:    $NAMESPACE   (all remaining resources)"
echo ""
echo "  All Loki log data and Grafana dashboards will be LOST."
echo ""
read -rp "  Type 'yes' to confirm deletion: " CONFIRM
echo ""

if [ "$CONFIRM" != "yes" ]; then
  echo -e "Aborted. No changes made."
  exit 0
fi

# =============================================================================
# STEP 1: Uninstall Alloy (first — stop log shipping before removing storage)
# =============================================================================
info "Step 1: Uninstalling Alloy..."

if helm status alloy -n "$NAMESPACE" >/dev/null 2>&1; then
  helm uninstall alloy --namespace "$NAMESPACE" --wait --timeout 3m
  success "Alloy uninstalled"
else
  warn "Alloy not found — skipping"
fi

# =============================================================================
# STEP 2: Uninstall Grafana
# =============================================================================
info "Step 2: Uninstalling Grafana..."

if helm status grafana -n "$NAMESPACE" >/dev/null 2>&1; then
  helm uninstall grafana --namespace "$NAMESPACE" --wait --timeout 3m
  success "Grafana uninstalled"
else
  warn "Grafana not found — skipping"
fi

# =============================================================================
# STEP 3: Uninstall Loki
# =============================================================================
info "Step 3: Uninstalling Loki..."

if helm status loki -n "$NAMESPACE" >/dev/null 2>&1; then
  helm uninstall loki --namespace "$NAMESPACE" --wait --timeout 3m
  success "Loki uninstalled"
else
  warn "Loki not found — skipping"
fi

# =============================================================================
# STEP 4: Delete Persistent Volume Claims
# =============================================================================
info "Step 4: Deleting PersistentVolumeClaims in $NAMESPACE..."

PVC_COUNT=$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$PVC_COUNT" -gt 0 ]; then
  kubectl delete pvc --all -n "$NAMESPACE" --timeout=60s
  success "PVCs deleted ($PVC_COUNT found)"
else
  warn "No PVCs found — skipping"
fi

# =============================================================================
# STEP 5: Delete ConfigMaps (including custom alloy configmap if applied)
# =============================================================================
info "Step 5: Cleaning up leftover ConfigMaps..."

for cm in alloy loki grafana; do
  if kubectl get configmap "$cm" -n "$NAMESPACE" >/dev/null 2>&1; then
    kubectl delete configmap "$cm" -n "$NAMESPACE"
    success "ConfigMap '$cm' deleted"
  fi
done

# =============================================================================
# STEP 6: Delete Namespace
# =============================================================================
info "Step 6: Deleting namespace: $NAMESPACE..."

if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  kubectl delete namespace "$NAMESPACE" --timeout=120s
  success "Namespace $NAMESPACE deleted"
else
  warn "Namespace $NAMESPACE not found — skipping"
fi

# =============================================================================
# STEP 7: Verify Cleanup
# =============================================================================
info "Step 7: Verifying cleanup..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Remaining Helm releases in $NAMESPACE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
helm list -n "$NAMESPACE" 2>/dev/null || echo "  (namespace gone — no releases)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Namespace status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get namespace "$NAMESPACE" 2>/dev/null || echo "  ✅ Namespace $NAMESPACE no longer exists"

# =============================================================================
# DONE
# =============================================================================
echo "  To redeploy, run:"
echo "  ./deploy-loki.sh"
