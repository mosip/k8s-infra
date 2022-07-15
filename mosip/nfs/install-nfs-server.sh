#!/bin/sh
# Script to install NFS server.
# Usage: ./install-nfs-server.sh.

#This function is to prompt weather user is able to access sudo or not!!!!
chkSudoer(){
  if [ "$USER"=="root" ]; then
  	return ;
  fi
  count=$( groups $USER | grep "sudo" | wc -l )
  if [ $count -eq 0 ]; then
    echo " $(tput setaf 1) User $USER does not has sudo access; EXITING $(tput sgr 0) "
    exit 1;
  else
    return
  fi
}

## The script starts from here
echo "This Script will Install NFS server."

chkSudoer    # calling chkSudoer function

read -p "Please Enter Environment Name: " env

if [ -z $env ]; then
  echo "Environment Name not provided; EXITING;";
  exit 1;
fi
nfsUser=nfsnobody
nfsStorage=/srv/nfs/mosip/$env
echo "\n$(tput setaf 9)[ Install NFS Server ] $(tput sgr 0)"
sudo apt update
sudo apt install nfs-kernel-server -y

echo "\n$(tput setaf 9)[ Add User For NFS ] $(tput sgr 0)"
sudo useradd $nfsUser
echo "User $nfsUser created"


echo "\n$(tput setaf 9)[ Create NFS Storage ] $(tput sgr 0)"
sudo mkdir -p $nfsStorage
sudo chown -R $nfsUser:$nfsUser $nfsStorage
sudo chmod 777 $nfsStorage
echo  "NFS storage $nfsStorage created."

echo  "\n$(tput setaf 9)[ Enable & Start NFS server ] $(tput sgr 0)"
sudo systemctl enable nfs-kernel-server
sudo systemctl start nfs-kernel-server
echo  "NFS server started and enabled."

echo  "\n$(tput setaf 9)[ Update NFS export file ] $(tput sgr 0)"
sudo echo "$nfsStorage *(rw,sync,no_root_squash,no_all_squash,insecure,subtree_check)" | sudo tee -a  /etc/exports
sudo cat /etc/exports | sort | uniq > /tmp/exports
sudo mv /tmp/exports /etc/exports
echo  "Updated NFS export file."

echo  "\n$(tput setaf 9)[ Export the NFS Share Directory ] $(tput sgr 0)"
sudo exportfs -rav

echo  "\n NFS Server Path: $nfsStorage "