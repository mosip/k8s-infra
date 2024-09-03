#!/bin/sh

# Install nfs-csi
## Usage: ./install-nfs-csi.sh [kubeconfig]

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

if [ -z "$NFS_SERVER" ]; then
  read -p "Please provide NFS SERVER: " NFS_SERVER
  read -p "Please provide NFS Path: " NFS_SERVER_LOCATION

  if [ -z "$NFS_SERVER" ]; then
    echo "NFS_SERVER \"$NFS_SERVER\" not provided; EXITING;";
    exit 1;
  fi
fi
if [ -z "$NFS_SERVER_LOCATION" ]; then
  read -p "Please provide NFS server path: " NFS_SERVER_LOCATION

  if [ -z "$NFS_SERVER_LOCATION" ]; then
    echo "NFS_SERVER_LOCATION \"$NFS_SERVER_LOCATION\" not provided; EXITING;";
    exit 1;
  fi
fi

echo "Installing NFS client provisioner"
helm install csi-driver-nfs -n $NS csi-driver-nfs/csi-driver-nfs \
-f values.yaml \
--set storageClass.parameters.server="$NFS_SERVER" \
--set storageClass.parameters.share="$NFS_SERVER_LOCATION" \
--version $CHART_VERSION

# Wait for the installation to complete
sleep 10

echo "Patching the StorageClass to set it as default"
kubectl patch storageclass nfs-csi \
  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

echo "NFS csi  installation and configuration completed."
