## Playbook Structure

The `main.yaml` file is divided into the following sections:

1. **Precheck**
   * Imports and executes the `pre-checks.yaml` playbook to perform preliminary checks.

2. **Ensure Required Tools and RKE2 are Installed**
   * Installs necessary tools (`wget`, `curl`, `jq`).
   * Creates the RKE2 configuration directory.
   * Installs RKE2 using the specified version.

3. **Configure Primary Node**
   * Imports and executes the `primary-node.yaml` playbook for configuring the primary control plane node.

4. **Configure Subsequent Nodes**
   * Imports and executes the `subsequent-nodes.yaml` playbook for configuring subsequent control plane nodes and workers.

## Variables

* `RKE2_PATH`: Path where the RKE2 configuration directory will be created.
* `INSTALL_RKE2_VERSION`: Version of RKE2 to be installed.

### Playbooks

The `pre-checks.yaml` playbook performs initial checks on all target hosts to ensure they meet the necessary prerequisites before proceeding with further configuration tasks.

The `pre-checks.yaml` playbook includes the following tasks:

1. **Check SSH Connectivity**
   * Uses the `ping` module to verify that the target hosts are reachable via SSH.

2. **Check HTTPS Internet Connectivity**
   * Uses the `uri` module to check if the target hosts can access the internet via HTTPS.
   * Verifies connectivity by sending a request to `https://www.google.com` and ensures the status code is 200.
   * Fails the playbook if the connectivity check fails.

3. **Check Sudo Access**
   * Executes the `whoami` command to determine if the user has sudo privileges.
   * Registers the result to check if the user is `root`.

4. **Fail if Sudo Access is Not Available**
   * Checks the result of the `whoami` command to ensure that the user has sudo privileges.
   * Fails the playbook if the user does not have sudo access.


### `any_errors_fatal: true`

* **Description**: This setting ensures that if any task within the playbook fails, the entire playbook execution stops immediately.
* **Purpose**: By setting `any_errors_fatal: true`, you ensure that errors are addressed promptly and do not go unnoticed, which helps prevent the playbook from continuing in an invalid state. This is particularly useful in pre-checks where failing to meet any prerequisite should halt further execution to avoid potential issues in later stages.

#### `control-plane-primary.yaml`
This playbook handles the configuration of the primary control plane node:

* Generates a unique RKE2 token.
* Copies the RKE2 configuration template to the appropriate directory.
* Replaces placeholders in the configuration file with node-specific details (e.g., token, node name, IP address).
* Starts and enables the RKE2 service.
* Configures `kubectl` and sets up `kubeconfig` for the primary control plane node.

#### `subsequent-roles.yaml`
This playbook configures subsequent control planes, agents, and etcd nodes:

* Waits for the primary control plane to be ready.
* Copies the appropriate RKE2 configuration template based on the node type (subsequent control plane, agents, etcd).
* Replaces placeholders in the configuration file with node-specific details.
* Starts and enables the RKE2 service on each node.

### Templates

The configuration templates are located in the `rke2` directory and are used by the playbooks to configure each node type. The templates include:

* `rke2-server-control-plane-primary.conf.template`: Used by the primary control plane.
* `rke2-server-control-plane.subsequent.conf.template`: Used by subsequent control planes.
* `rke2-agents.conf.template`: Used by agent nodes.
* `rke2-etcd-agents.conf.template`: Used by etcd nodes.

These templates contain placeholders that are dynamically replaced with actual values during the playbook execution.
