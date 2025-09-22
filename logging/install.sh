#!/bin/bash
# Installs Logging Operator and Crds
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=cattle-logging-system
ISTIO_ADDONS_CHART_VERSION=0.0.1-develop

echo "Creating namespace: $NS"
kubectl create namespace $NS || echo "Namespace $NS already exists."

function check_and_update_kibana_host() {
  echo "Please provide the Kibana Host."

  # Prompt for the Kibana Host
  read -p "Enter Kibana Host (eg: kibana.sandbox.xyz.net ) : " KIBANA_HOST

  echo "Kibana Host entered: $KIBANA_HOST"
  echo "NOTE: Please update the global ConfigMap with the same Kibana Host as part of the MOSIP external modules deployment."

  # Store Kibana Host in a ConfigMap for easy retrieval
  kubectl -n $NS create configmap kibana-config --from-literal=mosip_kibana_host=$KIBANA_HOST --dry-run=client -o yaml | kubectl apply -f -
  echo "Kibana Host stored in ConfigMap: kibana-config"
}

check_and_update_kibana_host

function installing_logging() {
  echo Updating helm repos
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo add banzaicloud-stable https://charts.helm.sh/stable
  helm repo update

  echo Installing Bitnami Elasticsearch and Kibana istio objects
  helm -n $NS install elasticsearch mosip/elasticsearch \
  -f es_values.yaml \
  --version 17.9.25 \
  --set image.repository="mosipint/elasticsearch" \
  --set image.tag="7.17.2-debian-10-r4" \
  --set kibana.image.repository="mosipint/kibana" \
  --set kibana.image.tag="7.17.2-debian-10-r0" \
  --set kibana.image.pullPolicy="IfNotPresent" \
  --wait
  echo Installed Bitnami Elasticsearch and Kibana istio objects

  KIBANA_HOST=$KIBANA_HOST
  KIBANA_NAME=elasticsearch-kibana

  echo Install istio addons
  helm -n $NS install istio-addons mosip/istio-addons --version $ISTIO_ADDONS_CHART_VERSION -f istio-addons-values.yaml

  echo Installing crds for logging operator
  helm -n $NS install rancher-logging-crd mosip/rancher-logging-crd --wait
  echo Installed crds for logging operator
  echo Installing logging operator
  helm -n $NS install rancher-logging mosip/rancher-logging -f values.yaml
  echo Installed logging operator
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_logging   # calling function

