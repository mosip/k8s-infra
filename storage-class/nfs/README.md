# NFS Setup
## Introduction
* The NFS is used as k8 persistence data storage.
* Since it contains all the persistent data from k8 cluster, you may backup this folder if needed.
* The NFS server runs on a separate node that the k8 cluster can access.
## Pre-requisites
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html). 
* Provision one VM for NFS Server. Make sure the user has sudo access on the NFS node.
* OS: Debian based. Recommended Ubuntu Server. 
* Command-line utilities:
    - `bash`
    - `awk`
* Create a copy of `hosts.ini.sample` as `hosts.ini`. Update the NFS machine details on the `hosts.ini` file.
* Make sure to have k8 cluster config file.
## NFS Server Installation
* Enable firewall with required ports:
  ```
  ansible-playbook -i ./hosts.ini nfs-ports.yaml
  ```
* Login to the NFS node to deploy the NFS server.
* The script uses environment variables to set the configuration:
  * `NFS_SERVER_LOCATION`: The directory path for the NFS storage (default: `/srv/nfs`)
  * `NFS_USER`: The user created for NFS operations (default: `nfsnobody`)
* To use the defaults, simply run:
  ```bash
  sudo ./install-nfs-server.sh
  ```
* To configure custom paths or a specific environment, pass the variables:
  ```bash
  sudo NFS_SERVER_LOCATION=/correct/path NFS_USER=nfsnobody ./install-nfs-server.sh
  ```
## NFS Client Provisioner Installation
* Run `./install-nfs-csi.sh` to deploy NFS client provisioner.
* The script supports interactive prompts, but you can also provide environment variables for a non-interactive installation:
  * `NFS_SERVER`: The IP or hostname of the NFS server
  * `NFS_SERVER_LOCATION`: The NFS path on the server
* To install interactively:
  ```bash
  ./install-nfs-csi.sh
  .....
  Please provide NFS SERVER: <NFS-SERVER>
  Please provide NFS Path: <NFS-SERVER-PATH>
  ```
* To install non-interactively using variables:
  ```bash
  NFS_SERVER=<NFS-SERVER> NFS_SERVER_LOCATION=<NFS-SERVER-PATH> ./install-nfs-csi.sh
  ```
## Post installation steps
* Check status of NFS Client Provisioner.
  ```
  kubectl -n nfs get deployment.apps/csi-driver-nfs
  ```
* check status of `nfs-csi` storage class.
  ```
   kubectl get storageclass
   NAME                 PROVISIONER                            RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
   nfs-csi           cluster.local/nfs-csi                     Retain          Immediate           true                   40s
  ```

* Login to the NFS node and check NFS server status:
  ```
  sudo systemctl status nfs-kernel-server.service
  ```
* Login to the NFS node and Check firewall status and verify all required ports are enabled.
  ```
  # sudo ufw status
  Status: active
  
  To                         Action      From
  --                         ------      ----
  OpenSSH                    ALLOW       Anywhere                  
  2049/tcp                   ALLOW       Anywhere                  
  OpenSSH (v6)               ALLOW       Anywhere (v6)             
  2049/tcp (v6)              ALLOW       Anywhere (v6)
  ```

## Set NFS Storage Class for deployments

* While deploying chart, set storage class to `nfs-csi`, enable persistence to `true` & set `persistence.size` .
  ```
  helm -n <namespace> install <name> <helm-repo>/<chart-name> \
  --set persistence.enabled=true \
  --set persistence.storageClass=nfs-csi \
  --set persistence.size=<storage> --version <chart-version>
  ```
* check whether pvc created with storage class `nfs-csi`.
  ```
  $ kubectl -n <namespace> get pvc
  NAME    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
  <name>  Bound    pvc-36d6e3ce-59bb-4f96-aea2-07c673356fac   5Gi        RWX            nfs-csi     60s
  ```

## Uninstall NFS Client Provisioner
* Run `./delete-nfs-cient-csi.sh` to uninstall `nfs-csi` helm/chart.
  ```bash
  ./delete-nfs-cient-csi.sh
  ```
