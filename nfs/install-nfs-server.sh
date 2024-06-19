#!/bin/bash

export NFS_PATH=${NFS_PATH:-/srv/nfs}
export NFS_USER=${NFS_USER:-nfsnobody}

if [ $USER != "root" ]; then
  echo "Run this as root"
  exit 1
fi

echo "\n$(tput setaf 9)[ Install NFS Server ] $(tput sgr 0)"

apt update
apt install nfs-kernel-server -y

echo "\n$(tput setaf 9)[ Add User For NFS ] $(tput sgr 0)"
useradd $NFS_USER
NFS_USER_USER_ID=$(id -u $NFS_USER)
NFS_USER_GROUP_ID=$(id -g $NFS_USER)
echo "User $NFS_USER created"

echo "\n$(tput setaf 9)[ Create NFS Storage ] $(tput sgr 0)"
mkdir -p $NFS_PATH
chown -R $NFS_USER:$NFS_USER $NFS_PATH
chmod 777 $NFS_PATH
echo "NFS storage $NFS_PATH created."

echo "\n$(tput setaf 9)[ Enable & Start NFS server ] $(tput sgr 0)"
systemctl enable nfs-kernel-server
systemctl start nfs-kernel-server
echo "NFS server started and enabled."

echo "\n$(tput setaf 9)[ Update NFS export file ] $(tput sgr 0)"
# TODO: The following is unsafe. Change to NFSv4 Auth.
echo "$NFS_PATH *(rw,sync,no_root_squash,no_all_squash,insecure,subtree_check)" | tee -a  /etc/exports
cat /etc/exports | sort | uniq > /tmp/exports
mv /tmp/exports /etc/exports
echo "Updated NFS export file."

echo "\n$(tput setaf 9)[ Export the NFS Share Directory ] $(tput sgr 0)"
exportfs -rav

echo "\n NFS Server Path: $NFS_PATH "
