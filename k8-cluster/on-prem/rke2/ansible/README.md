# RKE2 Kubernetes Cluster Setup using Ansible

An Ansible playbook and associated configurations to set up an RKE2 Kubernetes cluster. This setup includes:

* **Primary Control Plane Node:** Manages the cluster's control plane operations.
* **Subsequent Control Plane Nodes:** Provides high availability for the control plane.
* **Agent Nodes:** Runs workloads and application pods.
* **etcd Cluster:** Offers a distributed key-value store for Kubernetes.

The playbooks are designed to install RKE2, configure the nodes, and ensure the cluster is fully operational and ready for use.
## Prerequisites

Below are the pre-requisites for ansible playbook execution:

* Install Ansible on your local machine. For installation instructions, refer to the [Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html). version > 2.12.4
* Ensure that nodes are accessible from your local machine for SSH authentication.
* Verify that the SSH private key for the nodes is available on your local machine.
* Supported operating systems include Ubuntu 24.04 and other Debian-based distributions.

### Kubernetes setup via Ansible playbook

To run the playbooks and set up your RKE2 Kubernetes cluster, follow these steps:


1. **Create copy of `hosts.ini.sample` as `hosts.ini` and update the required details**

    ```bash
    cp hosts.ini.sample hosts.ini
    ```
    
2. **Execute `ports.yml` to enable ports on VM level using ufw:**
    ```bash
    ansible-playbook -i hosts.ini ports.yaml
    ```

3. **Run the playbook to provision RKE2 Cluster:**

    ```bash
    ansible-playbook -i hosts.ini main.yaml
    ```

    This command will start the installation and configuration process across all nodes.
