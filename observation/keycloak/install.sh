#!/bin/sh
## Script to install Keycloak for Rancher
## Usage: ./install.sh <iam_host_name> [kube_config_file]
## iam_host_name: Example iam.mosip.net

if [ $# -lt 1 ]; then
  echo "Usage: ./install.sh <iam_host_name> [kube_config_file]"; exit 1
fi
if [ $# -ge 2 ]; then
  export KUBECONFIG=$2
else
  export KUBECONFIG="$HOME/.kube/config"
fi
NS=keycloak

echo Creating namespace
kubectl create ns keycloak

helm repo add mosip https://mosip.github.io/mosip-helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

echo Installing
helm -n $NS template keycloak mosip/keycloak --version "7.1.18" -f values.yaml \
--set image.repository=mosipid/mosip-artemis-keycloak \
--set image.tag=1.2.0.1 \
--set image.pullPolicy=Always \
--set postgresql.image.repository="mosipint/postgresql" \
--set postgresql.image.tag="14.2.0-debian-10-r70" \
--set ingress.hostname=$1

