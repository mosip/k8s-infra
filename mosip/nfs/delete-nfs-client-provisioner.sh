#!/bin/sh
# Uninstall nfs-client-provisioner
## Usage: ./delete-nfs-provisioner.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi


NS=nfs
while true; do
    read -p "Are you sure you want to delete nfs-client-provisioner helm chart?(Y/n) " yn
    if [ $yn = "Y" ]
      then
        helm -n $NS delete nfs-client-provisioner
        break
      else
        break
    fi
done
