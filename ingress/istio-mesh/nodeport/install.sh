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

echo ------ IMPORTANT ---------
echo If you already have pods running with envoy sidecars, restart all of them NOW.  Check if all of them appear with command "istioctl proxy-status"
echo --------------------------
