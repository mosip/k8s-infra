#!/bin/bash
# Read the user input
# Script is used to restore the letsencrypt certificate from the client machine to the host machine

read -p "Enter the ip of remote node: " ip
read -p "Enter the user of remote node: " remote_user
read -p "Enter the pem file path: "  pem
read -p "Enter the letsencrypt zip file path: " zip_path
echo
scp -i ${pem} -r ${zip_path} ${remote_user}@${ip}:/etc/letsencrypt.zip
ssh -i ${pem} ${remote_user}@${ip} "bash -c 'cd /etc && unzip letsencrypt.zip && rm letsencrypt.zip '"