#!/bin/sh

# Install nfs-client-provisioner
## Usage: ./install-nfs-provisioner.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=nfs

echo Create $NS namespace
kubectl create ns $NS

echo Add helm stable repo
helm repo add stable https://charts.helm.sh/stable
helm repo update

read -p "Please provide NFS SERVER: " NFS_SERVER
read -p "Please provide NFS Path: " NFS_PATH

if [ -z "$NFS_SERVER" ]; then
  echo "NFS_SERVER not provided; EXITING;";
  exit 1;
fi
if [ -z "$NFS_PATH" ]; then
  echo "NFS_PATH not provided; EXITING;";
  exit 1;
fi

echo "Installing NFS client provisioner"
helm install nfs-client-provisioner -n $NS  \
--set image.repository=gcr.io/k8s-staging-sig-storage/nfs-subdir-external-provisioner  \
--set image.tag=v4.0.0 \
--set nfs.server="$NFS_SERVER" \
--set nfs.path="$NFS_PATH" \
--wait \
stable/nfs-client-provisioner
