# Cluster Installation

This guide uses RKE2 to set up a Kubernetes (K8s) cluster.

## Pre-requisites
1. Decide on the number of control planes (RKE2 servers). For high availability, the minimum number of nodes running control-plane should be 3. If your cluster has fewer than 3 nodes, run only 1 control-plane (always use an odd number of control-plane nodes). Refer to the [RKE2 documentation](https://docs.rke2.io).
2. The rest of the nodes will be Kubernetes workers (RKE2 agents).

## Setting Up Each Node
The following setup needs to be done on each node in the cluster.

1. **SSH into the Node**: Execute all the commands as the root user.

2. **Create the RKE2 Configuration Directory**:
    ```sh
    mkdir -p /etc/rancher/rke2
    ```

3. **Create and Configure the `config.yaml` File**:
    - For the first control-plane node, use `rke2-server.conf.primary.template`.
    - For subsequent control-plane nodes, use `rke2-server.conf.subsequent.template`.
    - For worker nodes, use `rke2-agent.conf.template`.
    - Ensure the token defined in the first control-plane node's configuration is used consistently across all nodes.

4. **Edit the `config.yaml` File**: Update the file with appropriate names, IPs, and tokens.

5. **Set the RKE2 Version**:
    ```sh
    export INSTALL_RKE2_VERSION="v1.28.10+rke2r1"
    ```

6. **Download RKE2**:
    ```sh
    curl -sfL https://get.rke2.io | sh -
    ```

7. **Start RKE2**:
    - On control-plane nodes:
        ```sh
        systemctl enable rke2-server
        systemctl start rke2-server
        ```
    - On worker nodes:
        ```sh
        systemctl enable rke2-agent
        systemctl start rke2-agent
        ```

8. **Export `KUBECONFIG`** (only on control-plane nodes):
    ```sh
    echo -e 'export PATH="$PATH:/var/lib/rancher/rke2/bin"\nexport KUBECONFIG="/etc/rancher/rke2/rke2.yaml"' >> ~/.bashrc
    source ~/.bashrc
    kubectl get nodes
    ```

## Adding Nodes to the Cluster
Guide to adding more nodes to an existing Kubernetes cluster:

1. From the `k8s-infra/rke2` directory, use either `rke2-server.conf.subsequent.template` or `rke2-agent.conf.template` based on whether the new node is a control-plane or worker node. Copy this file to `/etc/rancher/rke2/config.yaml` on the new node.
2. Configure the `config.yaml` with relevant values.
3. Ensure the RKE2 version matches across all nodes:
    ```sh
    export INSTALL_RKE2_VERSION="v1.28.10+rke2r1"
    ```
4. Download RKE2:
    ```sh
    curl -sfL https://get.rke2.io | sh -
    ```
5. Start the new RKE2 node:
    ```sh
    systemctl enable rke2-server
    systemctl start rke2-server
    ```

## Deleting Nodes from the Cluster
Guide to deleting nodes from an existing Kubernetes cluster:

1. Ensure the `PodDisruptionBudget` is set to "0" on the node being deleted.
2. Drain the node from the cluster:
    ```sh
    kubectl drain <nodename> --ignore-daemonsets --delete-emptydir-data
    ```
3. Delete the node from the cluster:
    ```sh
    kubectl delete node <nodename>
    ```
4. Verify the node has been deleted from your Kubernetes cluster.
5. Ensure the node IP is removed from the LoadBalancer/NGINX to avoid intermittent issues in the environment.

## NFS Client Provisioner
This section assumes an NFS server has already been set up. Install the NFS client provisioner on the cluster as follows:

1. Clone the repository:
    ```sh
    git clone https://github.com/mosip/k8s-infra.git
    git "checkout respective branch"
    ```
2. From the `k8s-infra/rke2/nfs` directory, run the install script:
    ```sh
    ./install.sh
    ```
    - Provide the `<NFS Node Internal IP>` and `<NFS server path>` parameters appropriately.

###UNINSTALLATION:

## WARNING
Uninstalling RKE2 deletes the cluster data and all of the scripts.

### Linux Uninstall
Depending on the method used to install RKE2, the uninstallation process varies.

#### RPM Method
To uninstall RKE2 installed via the RPM method from your system, simply run the commands corresponding to the version of RKE2 you have installed, either as the root user or through sudo. This will shut down the RKE2 process, remove the RKE2 RPMs, and clean up files used by RKE2.

```sh
/usr/bin/rke2-uninstall.sh
```
####Tarball Method
To uninstall RKE2 installed via the Tarball method from your system, simply run the command below. This will terminate the process, remove the RKE2 binary, and clean up files used by RKE2.

```SH
/usr/local/bin/rke2-uninstall.sh
```
###Windows Uninstall
To uninstall the RKE2 Windows Agent installed via the tarball method from your system, simply run the command below. This will shut down all RKE2 Windows processes, remove the RKE2 Windows binary, and clean up the files used by RKE2.

```sh
c:/usr/local/bin/rke2-uninstall.ps1
```
