#!/bin/sh
## Installs longhorn
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=longhorn-system
CHART_VERSION=1.2.3

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
