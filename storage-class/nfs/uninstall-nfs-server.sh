#!/bin/bash

function uninstalling_nfs() {
  export NFS_SERVER_LOCATION=${NFS_SERVER_LOCATION:-/srv/nfs}
  export NFS_USER=${NFS_USER:-nfsnobody}

  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "Run this as root"
    exit 1
  fi

  echo -e "\n$(tput setaf 9)[ Stop and Disable NFS server ] $(tput sgr 0)"
  systemctl stop nfs-kernel-server || true
  systemctl disable nfs-kernel-server || true
  echo "NFS server stopped and disabled."

  echo -e "\n$(tput setaf 9)[ Remove NFS server package ] $(tput sgr 0)"
  apt-get remove --purge nfs-kernel-server -y || true
  apt-get autoremove -y || true
  echo "NFS server package removed."

  echo -e "\n$(tput setaf 9)[ Clean up NFS export file ] $(tput sgr 0)"
  if [ -f /etc/exports ]; then
    tmp_exports="$(mktemp)"
    grep -Fv -- "$NFS_SERVER_LOCATION" /etc/exports > "$tmp_exports" || true
    mv "$tmp_exports" /etc/exports
    exportfs -rav || true
    echo "Cleaned up NFS export file."
  fi

  echo -e "\n$(tput setaf 9)[ Remove User For NFS ] $(tput sgr 0)"
  userdel "$NFS_USER" || echo "User $NFS_USER not found or could not be deleted"
  
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
uninstalling_nfs   # calling function
