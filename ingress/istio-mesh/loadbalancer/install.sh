#!/bin/bash
# Install ingress gateways
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

echo Operator init
istioctl operator init

function installing_istio() {
  echo Create ingress gateways and load balancers
  kubectl apply -f iop.yaml

  echo Wait for all resources to come up
  sleep 30
  kubectl -n istio-system rollout status deploy istiod
  kubectl -n istio-system rollout status deploy istio-ingressgateway
  kubectl -n istio-system rollout status deploy istio-ingressgateway-internal

  echo ------ IMPORTANT ---------
  echo If you already have pods running with envoy sidecars, restart all of them NOW.  Check if all of them appear with command "istioctl proxy-status"
  echo --------------------------
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_istio   # calling function