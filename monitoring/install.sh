#!/bin/bash
# Installs Monitoring
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=cattle-monitoring-system

echo Create namespace cattle-monitoring-system
kubectl create namespace $NS

function installing_monitoring() {
  echo Updating helm repos
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  echo Installing Crds for Monitoring
  helm -n $NS install monitoring-crd mosip/rancher-monitoring-crd
  echo Installing Monitoring
  helm -n $NS install monitoring mosip/rancher-monitoring -f values.yaml
  echo Installed monitoring
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_monitoring   # calling function
