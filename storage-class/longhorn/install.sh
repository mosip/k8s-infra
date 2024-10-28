#!/bin/bash
## Installs longhorn
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=longhorn-system
CHART_VERSION=1.4.2

function installing_longhorn() {
  echo "Adding Longhorn helm repo"
  helm repo add longhorn https://charts.longhorn.io
  helm repo update

  echo "Installing Longhorn"
  helm install longhorn longhorn/longhorn -n $NS               \
  --create-namespace --version $CHART_VERSION                  \
  --set defaultSettings.guaranteedEngineManagerCPU=5           \
  --set defaultSettings.guaranteedReplicaManagerCPU=5          \
  --set persistence.defaultClassReplicaCount=1                 \
  --set defaultSettings.defaultReplicaCount=1

  echo "Longhorn Installed !!!"
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_longhorn   # calling function