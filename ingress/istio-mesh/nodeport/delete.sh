#!/bin/bash
## Removes all the Istio resources along with Load Balancers.

## Usage: ./delete.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=istio-system
NS1=istio-operator

function deleting_istio() {
  echo Removing Istio components
  istioctl x uninstall --purge

  echo deleting $NS and $NS1 namespaces

  kubectl delete ns $NS $NS1
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
deleting_istio   # calling function