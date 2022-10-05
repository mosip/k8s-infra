# Scripts to save certificates

## While dismantling our environments sometimes we need to save the Letsencrypt certificate issued for the domain name.

1. Script such that it can be run from a client machine that will zip the certs on host and download them to the client  machine .
2. Reverse script to upload the certificates at the right place before starting to install.


**1. Script such that it can be run from a client machine that will zip the certs on host and download them to the client  machine .**

* Script to download certificates from host machine to client machine
  ![download-certs.sh.png](_images/download-certs.sh.png)<br>
* read -p "Enter the ip of remote node: " ip  = enter the server ip address
  ![enter the ip.png](_images/enter the ip.png)<br>
* read -p "Enter the user of remote node: " remote_user = enter the remote_username, root is the user on the remote server
  ![user of node.png](_images/user of node.png)<br>
* read -p "Enter the pem file path: "  pem =  enter the pem key of that host machine
  ![pem key path.png](_images/pem key path.png)<br>
* ssh -i ${pem} ${remote_user}@${ip} "bash -c 'cd /etc && zip -r letsencrypt.zip letsencrypt'" = it is cd into the  /etc  folder, then it is zipping the letsencrypt folder into the letsencrypt.zip file
  ![zip file.png](_images/zip file.png)<br>
* scp -i ${pem} -r ${remote_user}@${ip}:/etc/letsencrypt.zip . =  the letsencrypt zip file is being copied to the local client machine
  ![copy files.png](_images/copy files.png)<br>
* ssh -i ${pem} ${remote_user}@${ip} rm /etc/letsencrypt.zip = here we are deleting the letsencrypt zip file in the virtual machine
  ![all files.png](_images/all files.png)<br>


**2. Reverse script to upload the certificates at the right place before starting to install.**

* Script to upload certificates from client machine to host machine
  ![upload-certs.sh.png](_images/upload-certs.sh.png)<br>
* read -p "Enter the ip of remote node: " ip  = enter the server ip address
  ![enter the ip.png](_images/enter the ip.png)<br>
* read -p "Enter the user of remote node: " remote_user = enter the remote_username, root is the user on the remote server
  ![user of node.png](_images/user of node.png)<br>
* read -p "Enter the pem file path: "  pem =  enter the pem key of that host machine
  ![enter the ip.png](_images/enter the ip.png)<br>
* read -p "Enter the letsencrypt zip file path: " zip_path = enter the path where the zip file is present
  ![zip path.png](_images/zip path.png)
* scp -i ${pem} -r ${zip_path} ${remote_user}@${ip}:/etc/letsencrypt.zip = here it is taking the zip file as argument, sending that zip file out to the remote node again, copying it back
  ![letsencypt folder.png](_images/letsencypt folder.png)<br>
* ssh -i ${pem} ${remote_user}@${ip} "bash -c 'cd /etc/letsencrypt.zip && unzip letsencrypt.zip && rm letsencrypt.zip '" = it is going to unzip letsencrpt.zip file  and removing back
  ![files.png](_images/files.png)