#!/bin/sh
# Install ingress gateways

#NOTE: istioctl is specific to kubeconfig file. If you've more than one config files, please specify them like mentioned below:
#istioctl --kubeconfig <path-to-config-file> or use -c as shorthand for --kubeconfig.
echo Operator init
istioctl operator init

echo Create ingress gateways, load balancers and istio monitoring
kubectl apply -f iop.yaml
kubectl apply -f istio-monitoring/
echo Wait for all resources to come up
sleep 10
kubectl -n istio-system rollout status deploy istiod
kubectl -n istio-system rollout status deploy istio-ingressgateway
kubectl -n istio-system rollout status deploy istio-ingressgateway-internal

echo Installing gateways, proxy protocol, authpolicies
PUBLIC=$(kubectl get cm global -o jsonpath={.data.mosip-api-host})
INTERNAL=$(kubectl get cm global -o jsonpath={.data.mosip-api-internal-host})
echo Public domain: $PUBLIC
echo Internal dome: $INTERNAL
helm -n istio-system install istio-addons chart/istio-addons --set publicHost=$PUBLIC --set internalHost=$INTERNAL --set proxyProtocol.enabled=false

echo ------ IMPORTANT ---------
echo If you already have pods running with envoy sidecars, restart all of them NOW.  Check if all of them appear with command "istioctl proxy-status"
echo --------------------------
