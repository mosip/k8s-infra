# Kubernetes Infrastructure

## Overview
* This repo contains architecture and instructions to install Kubernetes (K8s) based clusters for MOSIP, Esignet, Inji and other DPG deployment.
* The k8s clusters may be installed on cloud or on-premise (on-prem).
* Repo also contains scripts and intruction for supporting infra around k8s cluster.
## Contents
* [Wireguard](./wireguard/README.md) : Modern day VPN setup steps and instructions.
* [k8-cluster](./k8-cluster/README.md).
  * Contains scripts and instructions to create k8 cluster across different mediums.
    * On-prem k8 clusters:
      * [RKE1](./k8-cluster/on-prem/rke1/README.md) based k8 cluster creation steps.
      * [RKE2](./k8-cluster/on-prem/rke2/README.md) based k8 cluster creation steps.
  * Cloud service providers:
    * [AWS](./k8-cluster/csp/aws/README.md) : based k8 cluster creation steps.
* [Ingress](./ingress/README.md) : Setup steps for ingress in k8 cluster to espose services.
* [Storage class](./storage-class) : Steps to setup and configure multiple types of storage classes for k8 cluster.
  * [nfs](./storage-class/nfs/README.md).
  * [longhorn](./storage-class/longhorn/README.md).
  * [EBS](./storage-class/ebs/README.md).
  * [ceph-csi](./storage-class/ceph/README.md)
* [Nginx](./nginx/) Webserver deployment steps. Used for exposing services to external world along with ingress in on-prem mode k8s clusters.
* [Alerting](./alerting/README.md)
* [logging](./logging/README.md)
* [monitoring](./monitoring/README.md)
* [Observation stack](observtaion/README.md) setup.
  * Contains below mentions apps for Observation stack.
    * [Rancher UI](apps/rancher-ui/README.md) Rancher UI installation.
    * [Keycloak](apps/keycloak/README.md) Installation for RBAC for k8 cluster access.
