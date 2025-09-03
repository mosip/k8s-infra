# EKS Cluster
## Introduction
* Amazon Elastic Kubernetes Service (EKS) is a managed Kubernetes service that makes it easy to run Kubernetes on AWS without needing to install and operate your own Kubernetes control plane or nodes.
* With EKS, AWS handles the management, monitoring, and maintenance of the Kubernetes control plane nodes, ensuring high availability and security.
* Various storage options available with EKS, such as EBS for block storage and EFS for file storage, to meet your application’s needs.
* Scale up and down the EKS cluster as per the need.
## EKS Setup
### Pre-requisites
* Apps to be downloaded on users personal computer.
  * [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) client version > 1.23.6
  * [helm](https://helm.sh/docs/intro/install/) client version > 3.8.2 and add `mosip` and `bitnami` repo as well.
  * [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html) version 0.121.0.
* AWS account and credentials with permissions to create EKS cluster.
* AWS credentials in `~/.aws/` folder as given [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).
* Save `~/.kube/config` file with another name. 
  * **IMPORTANT NOTE* :  As part of EKS cluster creation steps your existing kubeconfig (`~/.kube/config`) file will be overridden.
* Save `.pem` file from AWS console and store it in `~/.ssh/` folder. (Generate a new one if you do not have this key file).
## EKS cluster setup
* Copy `default.cluster.config.sample` as `my-cluster.cluster.config`.
  * Note:
    * For Observation cluster creation use `observation.cluster.config.sample`.
    * For MOSIP cluster creation use `mosip.cluster.config.sample`.
* Review and update the below mentioned parameters of `rancher.cluster.config` carefully.
  * name : cluster name.
  * region : AWS region for EKS cluster.
  * version : "1.24"
  * EC2 instance related details
    * instanceName
    * instanceType
    * desiredcapacity
    * volumeSize
    * volumeType
    * publicKeyName
  * update the details of the subnets to be used from vpc
* Execute `eksctl` command to create cluster.
  ```
  eksctl create cluster -f rancher.cluster.config
  ``` 
* Wait for the cluster creation to complete, generally it takes around 30 minutes to create or update cluster.
* Once EKS K8 cluster is ready below mentioned output will be displayed in the console screen.
  ```
  EKS cluster "my-cluster" in "region-code" region is ready
  ```
* The config file for the new cluster will be created on `~/.kube/config`.
* Make sure to backup and store the `~/.kube/config` with new name. e.g. `~/.kube/my-cluster.config`.
  ```
  mv ~/.kube/config ~/.kube/my-cluster.config
  ```
* Change file permission using below command:
  ```
  chmod 400 ~/.kube/obs-cluster.config
  ```
* Set the `KUBECONFIG` properly so that you can access the cluster.
  ```
  export KUBECONFIG=~/.kube/obs-cluster.config
  ```
* Test cluster access
  ```
  kubect get nodes
  ```
  * Command will list all the nodes of EKS cluster.
