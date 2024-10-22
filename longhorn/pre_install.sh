#!/bin/bash
## Installs prerequisites for LongHorn. 
NS=longhorn-system

echo Create $NS namespace
kubectl create namespace $NS

function installing_longhorn() {
  echo Installing iscsi
  kubectl apply -n $NS -f https://raw.githubusercontent.com/longhorn/longhorn/v1.4.2/deploy/prerequisite/longhorn-iscsi-installation.yaml

  echo Installing nfsv4 client
  kubectl apply -n $NS -f https://raw.githubusercontent.com/longhorn/longhorn/v1.4.2/deploy/prerequisite/longhorn-nfs-installation.yaml

  echo Pre-requisites for longhorn are installed
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_longhorn   # calling function
