# Wireguard Administrator’s Guide

## Overview
This document helps in creating wireguard configurations for the particular user.

### Steps to configure the wireguard

1. Login to the wireguard instance via ssh.
   ```
    ssh -i <pem> <user>@<ip>
   ```
2. Use `ls` cmd to see the list of files.
   ```
     ls
   ```
3. From the list, open `assigned.txt` file to assign the peer.
   ```
   vim assigned.txt
   ```
4. Add the peers with name as mentioned below.
   ```
   peer1 : peername
   ```
5. Change the directory to `config`.
   ```
     cd config
   ```
6. Use `ls` cmd to see the list of peers.

7. Change the directory to a particular peer which has been chosen in step4.
   ```
     cd peer1 
   ```
8. In this directory, list files and open `peer1.conf` file.
   ```
     vim peer1.conf file
   ```
9. In the `peer1.conf` file,
    * Delete the DNS IP.
    * Update the allowed IP's(subnet IP of AWS).
    * Share the conf file with the peer.
