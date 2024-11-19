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
  helm -n $NS install rancher-monitoring-crd mosip/rancher-monitoring-crd
  echo Installing Monitoring

  read -p "Please enter the env cluster-id: " cluster_id

  # Check if cluster_id is empty
  if [[ -z "$cluster_id" ]]; then
    echo "Error: cluster-id is required. Exiting."
    exit 1
  fi

  helm -n $NS install rancher-monitoring mosip/rancher-monitoring \
  -f values.yaml \
  --set grafana.global.cattle.clusterId=$cluster_id
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
