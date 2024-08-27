# RKE2 Kubernetes Cluster Setup using Ansible

This repository contains an Ansible playbook and associated configurations to set up an RKE2 Kubernetes cluster with a primary control plane, subsequent control plane nodes, agent nodes, and an etcd cluster. The playbooks are designed to install RKE2, configure nodes, and ensure the cluster is ready for use.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Inventory Setup](#inventory-setup)
- [Playbooks](#playbooks)
- [Templates](#templates)
- [Running the Playbook](#running-the-playbook)
- [Configuration Details](#configuration-details)

## Prerequisites

Before running the playbooks, ensure the following:

- **Ansible:** Installed on local machine.
- **Access to Nodes:** SSH access to all nodes (primary control plane, subsequent control planes, agents, etcd) with appropriate permissions.
- **Private Key:** Available for SSH authentication.
- **Supported OS:** Ubuntu or other Debian-based distributions.

## Inventory Setup

The `hosts.ini` file contains the configuration of your nodes. It is structured as follows:

```
# Primary control plane node. This is the main node where RKE2 will be installed first.
[control_plane_primary]
control-plane-1 ansible_host=<internal ip> ansible_user=root ansible_ssh_private_key_file=<pvt .pem file>

# Subsequent control plane nodes. These are additional control plane nodes that will be added to the cluster after the primary.
[control_plane_subsequent]
control-subsequent_plane-1 ansible_host=<internal ip> ansible_user=root ansible_ssh_private_key_file=<pvt .pem file>

# agent nodes. These nodes will run application workloads.
[agents]
agents-1 ansible_host=<internal ip> ansible_user=root ansible_ssh_private_key_file=<pvt .pem file>

# etcd nodes. These nodes will run the etcd database for Kubernetes, which is responsible for storing the cluster's state.
[etcd]
etcd-1 ansible_host=<internal ip> ansible_user=root ansible_ssh_private_key_file=<pvt .pem file>

# Global variables applied to all hosts in the inventory.
[all:vars]
# The version of RKE2 to install across the cluster.
INSTALL_RKE2_VERSION=v1.28.9+rke2r1
# The DNS domain name to use for the cluster.
cluster_domain=<cluster name>
# The path where RKE2 will be installed on each node.
RKE2_PATH=/etc/rancher/rke2

```


### Update the `hosts.ini` File

Update the `hosts.ini` file with the correct IP addresses, usernames, and paths to your private key files.

### Playbooks

#### `main.yaml`
This is the primary playbook that orchestrates the entire setup process. It includes the following tasks:

- Installing required tools (`wget`, `curl`).
- Creating the RKE2 configuration directory.
- Installing RKE2 using the specified version.

The playbook then imports two additional playbooks:

- `control-plane-primary.yaml`: Configures the primary control plane.
- `subsequent-roles.yaml`: Configures subsequent control plane nodes, agents, and etcd nodes.

#### `control-plane-primary.yaml`
This playbook handles the configuration of the primary control plane node:

- Generates a unique RKE2 token.
- Copies the RKE2 configuration template to the appropriate directory.
- Replaces placeholders in the configuration file with node-specific details (e.g., token, node name, IP address).
- Starts and enables the RKE2 service.
- Configures `kubectl` and sets up `kubeconfig` for the primary control plane node.

#### `subsequent-roles.yaml`
This playbook configures subsequent control planes, agents, and etcd nodes:

- Waits for the primary control plane to be ready.
- Copies the appropriate RKE2 configuration template based on the node type (subsequent control plane, agents, etcd).
- Replaces placeholders in the configuration file with node-specific details.
- Starts and enables the RKE2 service on each node.

### Templates

The configuration templates are located in the `rke2` directory and are used by the playbooks to configure each node type. The templates include:

- `rke2-server-control-plane-primary.conf.template`: Used by the primary control plane.
- `rke2-server-control-plane.subsequent.conf.template`: Used by subsequent control planes.
- `rke2-agents.conf.template`: Used by agent nodes.
- `rke2-etcd-agents.conf.template`: Used by etcd nodes.

These templates contain placeholders that are dynamically replaced with actual values during the playbook execution.

### Running the Playbook

To run the playbooks and set up your RKE2 Kubernetes cluster, follow these steps:

1. **Clone the repository:**

    ```bash
    git clone https://github.com/mosip/k8s-infra.git
    cd <repository-directory>
    ```

2. **Edit `hosts.ini`:**

    Update the `hosts.ini` file with your node details.
    
3. **Run the playbook to open ports:**
    ```bash
    ansible-playbook -i hosts.ini ports.yaml
    ```

4. **Run the playbook to provision RKE2 Cluster:**

    ```bash
    ansible-playbook -i hosts.ini main.yaml
    ```

    This command will start the installation and configuration process across all nodes.

### Configuration Details

#### Variables:

- **`INSTALL_RKE2_VERSION`**: Specifies the RKE2 version to install.
- **`cluster_domain`**: The domain name for your cluster.
- **`RKE2_PATH`**: The path where RKE2 configuration files are stored.

### Node Types

- **Primary Control Plane**: Manages the cluster and serves as the primary node.
- **Subsequent Control Planes**: Additional nodes that support the primary control plane.
- **agents**: Nodes that run workloads.
- **etcd**: Nodes responsible for the etcd database, which stores the cluster state
