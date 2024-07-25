#!/bin/sh

# Install nfs-client-provisioner
## Usage: ./install-nfs-provisioner.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=nfs
CHART_VERSION=v4.7.0

echo Create $NS namespace
kubectl create ns $NS

echo Add helm stable repo
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
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
helm install csi-driver-nfs -n $NS csi-driver-nfs/csi-driver-nfs \
-f values.yaml \
--set storageClass.parameters.server="$NFS_SERVER" \
--set storageClass.parameters.share="$NFS_PATH" \
--version $CHART_VERSION
