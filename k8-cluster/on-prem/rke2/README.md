# K8 Cluster Setup
This guide uses RKE2 to set up a Kubernetes (K8s) cluster.
## Introduction
The following guide uses [RKE2](https://docs.rke2.io/) to set up the Kubernetes (K8s) cluster.
## Pre-requisites
* Check usage and resource required for compute nodes in k8 cluster. For higher availability [check](https://docs.rke2.io/install/ha). 
* Make sure VM's/machines to be used for k8 cluster are able to communicate over defined [ports](https://docs.rke2.io/install/requirements#networking)
* The following tools are installed on all the VM's/machines and the client machine.
  ```ufw , wget , curl , kubectl , istioctl , helm , jq```
## Firewall Setup
Set up firewall rules on each of the VM's/machines. The following uses ufw to setup firewall.
* `ufw` commands to be executed on each of the VM's/machines:
  * SSH into each node VM/machine super user or change to superuser.
  * Run the following command for each rule in the following table
    ```
    ufw allow from <from-ip-range-allowed> to any port <port/range> proto <tcp/udp>
    ```
  * Example
    ```
    ufw allow from any to any port 22 proto tcp
    ufw allow from 10.3.4.0/24 to any port 9345 proto tcp
    ```
  * Enable ufw.
    ```
    ufw enable
    ufw default deny incoming
    ```
* Additional reference : [ RKE2 Networking Requirements](https://docs.rke2.io/install/requirements#networking).
* Ports to be opened in server nodes:
  |Protocal|Port|Accesibility|Description|
  |---|---|---|---|
  |TCP|22|RKE2 server and agent nodes over wireguard|SSH|
  |TCP|80|RKE2 server and agent nodes|Internal traffic|
  |TCP|443|RKE2 server and agent nodes|External traffic (if any apart fron nginx/loadbalancer)|
  |TCP|2381|RKE2 server and agent nodes|etcd metrics port|
  |TCP|2379|RKE2 server and agent nodes|etcd client port|
  |TCP|2380|RKE2 server and agent nodes|etcd peer port|
  |TCP|10250|RKE2 server and agent nodes|kubelet metrics|
  |TCP|9345|RKE2 server and agent nodes|RKE2 supervisor API|
  |TCP|6443|RKE2 server and agent nodes|Kubernetes API|
  |UDP|8472|RKE2 server and agent nodes|Canal CNI with VXLAN|
  |TCP|9099|RKE2 server and agent nodes|Canal CNI health checks|    
  |TCP|30000-32767|RKE2 server and agent nodes|NodePort port range|
* Ports to be opened in agent nodes
  |Protocal|Port|Accesibility|Description|
  |---|---|---|---|
  |TCP|22|RKE2 server and agent nodes over wireguard|SSH|
  |TCP|80|RKE2 server and agent nodes|Internal traffic|
  |TCP|443|RKE2 server and agent nodes|External traffic (if any apart fron nginx/loadbalancer)|
  |TCP|10250|RKE2 server and agent nodes|kubelet metrics|
* Ansible script to be used for opening ports via `ufw` on all VM's/machines.
  * Configure `Wireguard conf` and establish wireguard tunnel with Wireguard Bastion server.
  * Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on your personel computer or machine used to perform deployment.
  * Create a copy of `hosts.ini.sample` as `hosts.ini`.
  * Update `hosts.ini` with proper details of all the VM's/machines.
  * Execute Ansible command to open port on each nodes:
    ```
    ansible-playbook -i hosts.ini ports.yaml
    ```
  * Disable swap (perhaps not needed as swap is already disabled).
    ```
    ansible-playbook -i hosts.ini swap.yaml
    ```
## K8s setup
* Different types of nodes to be referenced moving ahead.
  * **Primary server node** : 
    * First node used for creating RKE2 k8 cluster is called primary server node.
    * These are control plane nodes that run the Kubernetes API server, scheduler, and controller manager.
    * They are responsible for managing the overall state of the Kubernetes cluster.
  * **Secondary server node** : 
    * All the nodes which will join the RKE2 k8 cluster created using primary node are called secondary nserver node.
    * These are control plane nodes that run the Kubernetes API server, scheduler, and controller manager.
    * They are responsible for managing the overall state of the Kubernetes cluster.
  * **Agent node** :
    * They run the Kubelet and Kube-proxy services, allowing them to manage and execute containers and handle networking. 
    * Nodes used as worker nodes in k8 cluster and are responsible for running the actual loads.
* Create RKE2 Configuration Directory in all nodes after establishing SSH connection with sudo user.
    ```
    mkdir -p /etc/rancher/rke2
    ```
* Generate random long string to be used as `token` during cluster creation and update the same in ```rke2-primary-conf.template``` and  ```rke2-secondary-conf.template```.
* Run this to get download rke2.
  ```
  curl -sfL https://get.rke2.io | sh -
  ```
* Set required RKE2 Version:
  ```
  export INSTALL_RKE2_VERSION="v1.28.10+rke2r1"
  ```
* Steps to be performed on all types of nodes.
  * **Primary server node**
    * Create and Configure and place `config.yaml`:
      * Update ```rke2-server-control-plane-primary.conf.template``` with nodal details.
        * Update `<node-name>` : name for the node to be distinguishable in k8 cluster.
        * Update `<node-internal-ip>` : internal ip of the node.
        * Update `<configure-some-token-here>` : token of the kubernetes cluster
      * copy ```rke2-server-control-plane-primary.conf.template``` as `config.yml` in primary server node.
        ```
        cp rke2-server-control-plane-primary.conf.template /etc/rancher/rke2/config.yaml
        ```
    * Enable and start RKE2:
      ```
      systemctl enable rke2-server
      systemctl start rke2-server
      ```
  * **Secondary server** 
    * Create and Configure and place `config.yaml`:
      * Update ```rke2-server-control-plane.subsequent.conf.template``` with nodal details for each VM's/machines.
        * Update `<node-name>` : name for the node to be distinguishable in k8 cluster.
        * Update `<node-internal-ip>` : internal ip of the node.
        * Update `<primary-server-ip>` : primary server ip of the RKE2 kubernetes cluster.
        * Update `<configure-some-token-here>` : token of the kubernetes cluster
      * copy ```rke2-server-control-plane.subsequent.conf.template``` as `config.yml` in secondary server node.
        ```
        cp rke2-server-control-plane.subsequent.conf.template /etc/rancher/rke2/config.yaml
        ```
    * Enable and start RKE2:
      ```
      systemctl enable rke2-server
      systemctl start rke2-server
  * **Etcd & Worker nodes**
    * Create and Configure and place `config.yaml`:
      * Update ```rke2-etcd-worker.conf.template``` with agent nodal details for each VM's/machines.
        * Update `<node-name>` : name for the node to be distinguishable in k8 cluster.
        * Update `<node-internal-ip>` : internal ip of the node.
        * Update `<primary-server-ip>` : primary server ip of the RKE2 kubernetes cluster.
        * Update `<configure-some-token-here>` : token of the kubernetes cluster
      * copy ```rke2-etcd-worker.conf.template``` as `config.yml` in agent server node.
        ```
        cp rke2-etcd-worker.conf.template /etc/rancher/rke2/config.yaml
        ```
    * Enable and start RKE2:
      ```
      systemctl enable rke2-agent
      systemctl start rke2-agent
      ```
  * **Worker nodes**
    * Create and Configure and place `config.yaml`:
      * Update ```rke2-worker.conf.template``` with agent nodal details for each VM's/machines.
        * Update `<node-name>` : name for the node to be distinguishable in k8 cluster.
        * Update `<node-internal-ip>` : internal ip of the node.
        * Update `<primary-server-ip>` : primary server ip of the RKE2 kubernetes cluster.
        * Update `<configure-some-token-here>` : token of the kubernetes cluster
      * copy ```rke2-worker.conf.template``` as `config.yml` in agent server node.
        ```
        cp rke2-worker.conf.template /etc/rancher/rke2/config.yaml
        ```
    * Enable and start RKE2:
      ```
      systemctl enable rke2-agent
      systemctl start rke2-agent
      ```
* Export KUBECONFIG (only on control-plane nodes):
  ```
  echo -e 'export PATH="$PATH:/var/lib/rancher/rke2/bin"\nexport KUBECONFIG="/etc/rancher/rke2/rke2.yaml"' >> ~/.bashrc
  source ~/.bashrc
  kubectl get nodes
  ```
## Adding Nodes to the Cluster
Guide to adding more nodes to an existing Kubernetes cluster:
* From the k8s-infra/rke2 directory, use either `rke2-primary-conf.template` or `rke2-secondary-conf.template` based on whether the new node is a control-plane or worker node.
* Copy required config template file to /etc/rancher/rke2/config.yaml on the new node based upon type of node.
* Update `config.yml` with relevant values.
* Download RKE2 binary:
  ```
  curl -sfL https://get.rke2.io | sh -
  ```
* Start the new RKE2 node with relevant command:
  * For adding server node:
    ```
    systemctl enable rke2-server
    systemctl start rke2-server
    ```
  * For adding agent node:
    ```
    systemctl enable rke2-agent
    systemctl start rke2-agent 
    ```
## Deleting Nodes from the Cluster
* Guide to deleting nodes from an existing k8 cluster:
1. Ensure the `PodDisruptionBudget` is set to **0** on the node being deleted.
1. Drain the node from the k8 cluster:
  ```
  kubectl drain <nodename> --ignore-daemonsets --delete-emptydir-data
  ```
1. Delete the node from the k8 cluster:
  ```
  kubectl delete node <nodename>
  ```
1. Verify the node has been deleted from your k8 cluster.
1. Ensure the node IP is removed from the LoadBalancer/NGINX to avoid intermittent issues in the environment.
## RKE2 Uninstallation Guide
* This document provides instructions for uninstalling RKE2 (Rancher Kubernetes Engine 2) from your system.
* The uninstallation process varies depending on the method used for installation.
### RPM method
* To uninstall RKE2 installed via the RPM method, execute the following command as the root user or with `sudo` privileges.
* This will shut down the RKE2 process, remove the RKE2 RPM packages, and clean up files used by RKE2.

  ```sh
  sudo /usr/bin/rke2-uninstall.sh
  ```
### Tarball Method
* To uninstall RKE2 installed via the tarball method, execute the following command.
* This will terminate the RKE2 process, remove the RKE2 binary, and clean up files used by RKE2.
  ```sh
  sudo /usr/local/bin/rke2-uninstall.sh
  ```
### Windows Uninstall
* To uninstall the RKE2 Windows Agent installed via the tarball method, execute the following PowerShell script.
* This will shut down all RKE2 Windows processes, remove the RKE2 Windows binary, and clean up the files used by RKE2.
  ```poweshell
  c:/usr/local/bin/rke2-uninstall.ps1
  ```
