#!/bin/bash
# Uninstalls all logging helm charts
## Usage: ./delete.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi
NS=cattle-logging-system

function deleting_logging() {
  while true; do
    read -p "Are you sure you want to delete ALL logging helm charts from $KUBECONFIG cluster?(Y/n) " yn
    if [ $yn = "Y" ]
      then
        helm -n $NS delete elasticsearch
        helm -n $NS delete istio-addons
        break
      else
        break
    fi
  done
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
deleting_logging   # calling function
