#!/bin/bash

function installing_nfs() {
  export NFS_SERVER_LOCATION=${NFS_SERVER_LOCATION:-/srv/nfs}
  export NFS_USER=${NFS_USER:-nfsnobody}

  if [ "$USER" != "root" ]; then
    echo "Run this as root"
    exit 1
  fi

  echo -e  "\n$(tput setaf 9)[ Install NFS Server ] $(tput sgr 0)"

  apt update
  apt install nfs-kernel-server -y

  echo -e "\n$(tput setaf 9)[ Add User For NFS ] $(tput sgr 0)"
  useradd "$NFS_USER"
  echo "User $NFS_USER created"

  echo -e "\n$(tput setaf 9)[ Create NFS Storage ] $(tput sgr 0)"
  mkdir -p "$NFS_SERVER_LOCATION"
  chown -R "$NFS_USER":"$NFS_USER" "$NFS_SERVER_LOCATION"
  chmod 777 "$NFS_SERVER_LOCATION"
  echo "NFS storage $NFS_SERVER_LOCATION created."

  echo -e "\n$(tput setaf 9)[ Enable & Start NFS server ] $(tput sgr 0)"
  systemctl enable nfs-kernel-server
  systemctl start nfs-kernel-server
  echo "NFS server started and enabled."

  echo -e "\n$(tput setaf 9)[ Update NFS export file ] $(tput sgr 0)"
  # TODO: The following is unsafe. Change to NFSv4 Auth.
  echo -e "$NFS_SERVER_LOCATION *(rw,sync,no_root_squash,no_all_squash,insecure,subtree_check)" | tee -a  /etc/exports
  cat /etc/exports | sort | uniq > /tmp/exports
  mv /tmp/exports /etc/exports
  echo "Updated NFS export file."

  echo -e "\n$(tput setaf 9)[ Export the NFS Share Directory ] $(tput sgr 0)"
  exportfs -rav

  echo "\n NFS Server Path: $NFS_SERVER_LOCATION "
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_nfs   # calling function