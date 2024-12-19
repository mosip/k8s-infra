#!/bin/bash
# Installs Logging Operator and CRDs
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=cattle-logging-system

echo "Creating namespace: $NS"
kubectl create namespace $NS || echo "Namespace $NS already exists"

function check_and_update_kibana_host() {
  echo "Checking for Kibana Host in global ConfigMap..."
  KIBANA_HOST=$(kubectl get cm global -o jsonpath='{.data.mosip-kibana-host}' 2>/dev/null || echo "")

  if [ -z "$KIBANA_HOST" ]; then
    read -p "Enter Kibana Host: " KIBANA_HOST
    echo "Updating global ConfigMap with Kibana Host..."
    kubectl patch cm global --type merge -p "{\"data\": {\"mosip-kibana-host\": \"$KIBANA_HOST\"}}" || \
    kubectl create cm global --from-literal=mosip-kibana-host="$KIBANA_HOST"
    echo "Kibana Host updated in global ConfigMap."
  else
    echo "Kibana Host found in global ConfigMap: $KIBANA_HOST"
  fi
}

function installing_logging() {
  check_and_update_kibana_host

  echo "Updating Helm repositories..."
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo add banzaicloud-stable https://charts.helm.sh/stable
  helm repo update

  echo "Installing Bitnami Elasticsearch..."
  helm -n $NS install elasticsearch mosip/elasticsearch -f es_values.yaml --version 17.9.25 --wait
  echo "Installed Bitnami Elasticsearch."

  KIBANA_HOST=$(kubectl get cm global -o jsonpath='{.data.mosip-kibana-host}')
  KIBANA_NAME=elasticsearch-kibana

  echo "Installing Istio Addons..."
  helm -n $NS install istio-addons chart/istio-addons \
    --set kibanaHost=$KIBANA_HOST \
    --set installName=$KIBANA_NAME

  echo "Installing CRDs for Logging Operator..."
  helm -n $NS install rancher-logging-crd mosip/rancher-logging-crd --wait
  echo "Installed CRDs for Logging Operator."

  echo "Installing Logging Operator..."
  helm -n $NS install rancher-logging mosip/rancher-logging -f values.yaml
  echo "Installed Logging Operator."
  return 0
}

# Set commands for error handling.
set -e
set -o errexit   ## Exit the script if any statement returns a non-true return value
set -o nounset   ## Exit the script if you try to use an uninitialized variable
set -o errtrace  # Trace ERR through 'time command' and other functions
set -o pipefail  # Trace ERR through pipes

installing_logging   # Calling the function
