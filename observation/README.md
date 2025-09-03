# Observation Stack
## Introduction
* Observation k8s Cluster contains necesary application required for management and update of other k8 cluster.
* This is one for an organisation.
* With good resource compute on nodes it can import/create all the other MOSIP's k8 clusters env.
* Applications deployed in Observation cluster for observation puspose:
  * Rancher UI
    * Rancher is an open-source platform that provides a user-friendly interface and tools for managing k8 clusters.
    * Rancher simplifies the deployment, operation, and management of Kubernetes at scale across any infrastructure, including on-premises data centers, public clouds, and hybrid environments.
    * The Rancher UI (User Interface) is one of its most powerful features, offering a centralized dashboard for managing multiple Kubernetes clusters.
  * Keycloak
    * Keycloak is an OAuth 2.0 compliant Identity Access Management (IAM) system used to manage the access to Rancher for cluster controls.
    * Keycloak will be used for user RBAC to Rancher UI used for updating and managing existing k8 cluster for users and groups.
## Setup Observation Stack:
* On-prem Observation stack deployment:
  * Setup [Wireguard](../wireguard/README.md) for private channel access.
  * k8 cluster creation:
    * Requirement for the same is listed [here](./onprem-requirement.md).
    * Create k8 cluster for observation using [RKE1](../k8-cluster/on-prem/rke1/README.md).
  * Deploy ingess nginx controller as Nodeport following  mentioned [steps](../ingress/ingress-nginx/README.md#deploy-as-nodeport).
  * Setup NFS as storage class using mentioned [steps](../storage-class/nfs/README.md). Note: Use seperate server with disk as per requirement for nfs, for sandbox you can use the nginx VM as NFS server.
  * Setup Nginx server for managing external access using [steps](../nginx/observation/README.md).
  * Deploy Rancher UI using mentioned [steps](../apps/rancher-ui/README.md).
  * Deploy Keycloak and integrate keycloak with rancher ui using mentioned [steps](../apps/keycloak/README.md).
* EKS Observation stack deployment:
  * Setup [Wireguard](../wireguard/README.md) for private channel access.
  * k8 cluster creation:
    * Setup EKS cluster for observation using mentioned [steps](../k8-cluster/csp/aws/README.md).
    * Use `observation.cluster.config.sample` for k8 cluster creation.
  * Deploy ingess nginx controller as Loadbalancer following mentioned [steps](../ingress-nginx/README.md#deploy-as-loadbalancer-nlb-in-aws).
  * Check if EBS storage class is present or not:
    ```
    kubectl get sc
    ```
  * In case storage class is not set configure the storage class using mentioned [steps](../storage-class/ebs/README.md#different-ebs-storage-classes).
  * Deploy Rancher UI using mentioned [steps](../apps/rancher-ui/README.md).
  * Deploy Keycloak and integrate keycloak with rancher ui using mentioned [steps](../apps/keycloak/README.md).
## Import k8 cluster into rancher ui:
* In order to manage any cluster from this Observation stack need to import the cluster to rancher ui by following below mentioned steps.
  * Login as admin in Rancher console.
  * Select `Import` Existing for cluster addition.
  * Select `Generic` as cluster type to add.
  * Fill the `Cluster Name` field with unique cluster name and select `Create`.
  * kubectl commands to be executed in the kubernetes cluster will appear.
  * Copy the command and execute from your PC (make sure your `kube-config` file is correctly set to required cluster).
    ```
    kubectl apply -f https://rancher.e2e.mosip.net/v3/import/pdmkx6b4xxtpcd699gzwdtt5bckwf4ctdgr7xkmmtwg8dfjk4hmbpk_c-m-db8kcj4r.yaml
    ```
* Wait for few seconds after executing the command for the cluster to get verified.
* Your cluster is now added to the rancher management server.
