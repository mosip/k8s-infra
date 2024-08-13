#!/bin/sh
# Uninstall nfs-client-provisioner
## Usage: ./delete-nfs-provisioner.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi


NS=nfs
while true; do
    read -p "Are you sure you want to delete nfs-csi helm chart?(Y/n) " yn
    if [ $yn = "Y" ]
      then
        helm -n $NS delete nfs-csi
        break
      else
        break
    fi
done
