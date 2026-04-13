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
#       loki-cluster-output.yaml
#       loki-cluster-flow.yaml
# =============================================================================

set -e   # Exit on any error

# =============================================================================
# CONFIGURATION — Edit these values before running
# =============================================================================
NAMESPACE="loki-monitoring"
LOKI_CHART_VERSION="6.55.0"
ALLOY_CHART_VERSION="1.6.2"
GRAFANA_PASSWORD="Mosip@Loki123!"   # ⚠️  CHANGE THIS

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
info "Running pre-flight checks..."

command -v kubectl >/dev/null 2>&1 || error "kubectl not found. Please install kubectl."
command -v helm    >/dev/null 2>&1 || error "helm not found. Please install helm v3."

# Check cluster connectivity
kubectl cluster-info >/dev/null 2>&1 || error "Cannot connect to Kubernetes cluster. Check kubeconfig."
success "Cluster connectivity verified"

# Check required files exist
for f in loki-values.yaml grafana-values.yaml loki-cluster-output.yaml loki-cluster-flow.yaml; do
  [ -f "$f" ] || error "Required file not found: $f. Run this script from the deployment directory."
done
success "All required YAML files found"

# =============================================================================
# STEP 1: Create Namespace
# =============================================================================
info "Step 1: Creating namespace: $NAMESPACE"
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 && \
  warn "Namespace $NAMESPACE already exists — skipping creation" || \
  kubectl create namespace "$NAMESPACE"
success "Namespace ready: $NAMESPACE"

# =============================================================================
# STEP 2: Add Helm Repos
# =============================================================================
info "Step 2: Adding Grafana Helm repository..."
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo add grafana-community https://grafana-community.github.io/helm-charts 2>/dev/null || true
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
info "Step 4: Deploying Grafana..."

if helm status grafana -n "$NAMESPACE" >/dev/null 2>&1; then
  warn "Grafana already installed — upgrading..."
  helm upgrade grafana grafana/grafana \
    --namespace "$NAMESPACE" \
    -f grafana-values.yaml \
    --set adminPassword="$GRAFANA_PASSWORD" \
    --wait --timeout 5m
else
  helm install grafana grafana-community/grafana \
    --namespace "$NAMESPACE" \
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

# =============================================================================
# STEP 6: Verify Deployment
# =============================================================================
info "Step 6: Verifying deployment..."

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
# STEP 7: Print Access Info
# =============================================================================
echo "  Access Grafana:"
echo "  ─────────────────────────────────────────────────────"
echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo "  Open: http://localhost:3000"
echo "  User: admin"
echo "  Pass: $GRAFANA_PASSWORD"
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
# STEP 8: Quick Health Check
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
