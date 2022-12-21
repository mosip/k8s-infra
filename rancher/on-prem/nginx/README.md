# Nginx Reverse Proxy

## Overview
This document describes how to install and setup Nginx reverse proxy that directs traffic to Ingress controller running on K8s cluster.

## Prerequisites
* Ubuntu (or Debian based OS).
* SSL certificate as given in [SSL Certificates with Letsencrypt](../../../docs/wildcard-ssl-certs-letsencrypt.md). The SSL certificate and key pair to be copied into this machine. The script will prompt for the path to these. 

## Install
```sh
 sudo ./install.sh
```

## Post installation
* After installation check Nginx status:
```
sudo systemctl status nginx
```

## Uninstall
```
sudo apt purge nginx nginx-common
```
