#!/bin/sh
# Uninstalls longhorn
## Usage: ./delete.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=longhorn-system

while true; do
    read -p "Are you sure you want to delete longhorn helm charts?(Y/n) " yn
    if [ $yn = "Y" ]
      then
        echo Removing longhorn
        helm -n $NS delete longhorn
        echo Removing iscsi
        kubectl delete -n $NS -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.3/deploy/prerequisite/longhorn-iscsi-installation.yaml
        echo Removing nfsv4 client
        kubectl delete -n $NS -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.3/deploy/prerequisite/longhorn-nfs-installation.yaml
        break
      else
        break
    fi
done