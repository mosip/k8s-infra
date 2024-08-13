# Wireguard
## Introduction
* WireGuard is a modern, simple, and highly effective VPN (Virtual Private Network) protocol designed for simplicity, speed, and security.
* It operates at the network layer and is designed to be easy to configure and deploy.
* WireGuard is included in the Linux kernel since version 5.6 and is also available for various other operating systems, including Windows, macOS, BSD, and Android.
* Wireguard listens on UDP port 51820.
## Setup Wireguard Bastion Server
* VM/Machine with minimum 2VPU, 4GB RAM, 8GB disk storage is needed for Bastion server setup.
* Open ports and install docker on Wireguard VM.
  * Create copy of `hosts.ini.sample` as `hosts.ini` and update the required details for VM/machine.
    ```
    cp hosts.ini.sample hosts.ini
    ```
  * execute ports.yml to enable ports on VM level using ufw:
    ```
    ansible-playbook -i hosts.ini ports.yaml
    ```
  * **Note**:
    * Permission of the pem files to access nodes should have 400 permission. 
      ```
      sudo chmod 400 ~/.ssh/privkey.pem
      ```
    * These ports are only needed to be opened for sharing packets over UDP.
    * Take necessary measure on firewall level so that the Wireguard server can be reachable on 51820/udp.
  * execute docker.yml to install docker and add user to docker group:
    ```
    ansible-playbook -i hosts.ini docker.yaml
    ```
* Installing Wireguard
  * Establish SSH connection to wireguard VM/Machine.
  * Create directory for storing wireguard config files.
    ```
    mkdir -p wireguard/config
    ```
  * Install and start wireguard server using docker as given below:
    ```
    sudo docker run -d \
    --name=wireguard \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=Asia/Calcutta \
    -e PEERS=30 \
    -p 51820:51820/udp \
    -v /home/ubuntu/wireguard/config:/config \
    -v /lib/modules:/lib/modules \
    --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
    --restart unless-stopped \
    ghcr.io/linuxserver/wireguard
    ```
  * **Note**:
    * Increase the no. of peers above in case more than 30 wireguard client confs (-e PEERS=30) are needed.
    * Change the directory to be mounted to wireguard docker as per need. 
    * All your wireguard confs will be generated in the mounted directory (-v /home/ubuntu/wireguard/config:/config).
## Setup Wireguard Client
* Install [Wireguard client](https://www.wireguard.com/install/) in your PC.
* Assign `wireguard.conf`:
  * Establish SSH connection to the wireguard server VM/machine.
  * Move to the Config directory
    ```
    cd /home/ubuntu/wireguard/config
    ```
  * Decide on the PEER to be allocated to multiple users.
    * Create `assigned.txt` file to assign and keep track of peer files allocated to respective users.
    * Update `assigned.txt` everytime some peer is allocated to someone.
    * Suggested Format of `assigned.txt`
      ```
      peer1 : peername
      peer2 : peername
      ```
  * Use `ls` command to see the list of peers.
  * Move to selected peer directory, and add mentioned changes in `peer.conf`:
    ```
    cd peer1
    nano peer1.conf
    ```
    * Delete the DNS IP.
    * Update the allowed IP's to subnets CIDR ip . e.g. 10.10.20.0/23
  * Share the updated peer.conf with respective peer to connect to wireguard server from Personel PC.
* Add `peer.conf` recieved from Wireguard Admin to `/etc/wireguard` directory as wg0.conf.
  ```
  mv peer1.conf /etc/wireguard/wg0.conf
  ```
* Start the wireguard client and check the status:
  ```
  sudo systemctl start wg-quick@wg0
  sudo systemctl status wg-quick@wg0
  ```
* Once connected to wireguard, you should be now able to access VM's/machines and establish SSH connection using private IP’s.
