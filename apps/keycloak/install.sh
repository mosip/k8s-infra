#!/bin/bash
## Script to install Keycloak for Rancher
## Usage: ./install.sh <iam_host_name> [kube_config_file]
## iam_host_name: Example iam.mosip.net

if [ $# -ge 1 ]; then
export KUBECONFIG=$1
fi
NS=keycloak

echo Creating namespace
kubectl create ns $NS

function installing_keycloak() {
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update

  echo Installing
  helm -n $NS install keycloak mosip/keycloak --version "7.1.18" -f values.yaml --set ingress.hostname=$1
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
deleting_keycloak   # calling function