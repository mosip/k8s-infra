# Requirements for AWS MOSIP Cluster

Listed below are hardware, network and certificate requirements for **MOSIP sandbox** on AWS. Note that [Rancher cluster (AWS) requirements](../../rancher/aws) are not covered here.

## Hardware requirements
The following number of EC2 nodes/instances will be required

| No. of nodes | No. of vCPUs | RAM | Storage | AWS Type of each node | Used as part of |
|---|---|---|---|---|---|
| 6 | 8 vCPU | 32GB | 64 GB | t3.2xlarge | Cluster nodes |
| 1 | 2 vCPU | 4 GB | 8 GB | t2.micro | Wireguard Bastion Node |

All the above nodes should be in the same VPC.

## LoadBalancers
Two loadbalancers will be required, one for each ingressgateway, as describe in [the reference image](../README.md). These will automatically be created upon installation of the istio & ingressgateways.

## DNS Requirements
The following DNS mappings will be required.

| Hostname | Domain | Mapped to |
|---|---|---|
| installation-domain | sandbox.xyz.net | Internal ip of Nginx Node |
| mosip-api-host | api.sandbox.xyz.net | Public ip of Nginx node |
| mosip-api-internal-host | api-internal.sandbox.xyz.net | Internal ip |
| mosip-prereg-host | prereg.sandbox.xyz.net | Public ip |
| mosip-activemq-host | activemq.sandbox.xyz.net | Internal ip |
| mosip-kibana-host | kibana.sandbox.xyz.net | Internal ip |
| mosip-regclient-host | regclient.sandbox.xyz.net | Internal ip |
| mosip-admin-host | admin.sandbox.xyz.net | Internal ip |
| mosip-minio-host | minio.sandbox.xyz.net | Internal ip |
| mosip-kafka-host | kafka.sandbox.xyz.net | Internal ip |
| mosip-iam-external-host | iam.sandbox.xyz.net | Internal ip |
| mosip-postgres-host | postgres.sandbox.xyz.net | Internal ip |
| mosip-pmp-host | pmp.sandbox.xyz.net | Internal ip |
| mosip-onboarder-host | onboarder.sandbox.xyz.net | Internal ip |
| mosip-resident-host | resident.sandbox.xyz.net | Public ip of nginx node |

Note: The above table is just a placeholder for hostnames, the actual name itself varies from organisation to organisation.  A sample hostname list is given at [global_configmap.yaml.sample](https://github.com/mosip/mosip-infra/blob/develop/deployment/v3/cluster/global_configmap.yaml.sample) <br/>
Note: Only proceed to DNS mapping after the ingressgateways are installed and the loadbalancers are setup.

## Certificate Requirements

* Depending upon the above hostnames, procure SSL certificates for domain and subdomains. E.g. `sandbox.mosip.net` and `*.sandbox.mosip.net`.
