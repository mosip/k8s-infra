#!/bin/bash
# Installs Elasticsearch
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=cattle-logging-system

function installing_logging() {
  echo Create namespace logging
  kubectl create namespace $NS

  echo Updating helm repos
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update

  echo Installing Bitnami Elasticsearch and Kibana
  helm -n $NS install elasticsearch mosip/elasticsearch -f es_values.yaml --version 17.9.25 --wait

  KIBANA_HOST=$(kubectl get cm global -o jsonpath={.data.mosip-kibana-host})
  KIBANA_NAME=elasticsearch-kibana

  echo Install istio addons
  helm -n $NS install istio-addons chart/istio-addons --set kibanaHost=$KIBANA_HOST --set installName=$KIBANA_NAME
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_logging   # calling function
