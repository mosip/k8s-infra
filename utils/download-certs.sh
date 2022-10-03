#!/bin/bash    
# Read the user input   
# Script is used to download the letsencrypt certificate from host to client machine

read -p "Enter the ip of remote node: " ip  
read -p "Enter the user of remote node: " remote_user  
read -p "Enter the pem file path: "  pem
echo
ssh -i ${pem} ${remote_user}@${ip} "bash -c 'cd /etc && zip -r letsencrypt.zip letsencrypt'"
scp -i ${pem} -r ${remote_user}@${ip}:/etc/letsencrypt.zip .
ssh -i ${pem} ${remote_user}@${ip} rm /etc/letsencrypt.zip