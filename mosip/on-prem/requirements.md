# Requirements for On-prem MOSIP Cluster Sandbox

Listed below are hardware, network and certificate requirements to setup a **MOSIP sandbox** on-prem.  Note that requirements for [Rancher cluster](../../rancher/on-prem) are not covered here.

## Hardware requirements
|Purpose|vCPUs|RAM|Storage (SSD) |Number of VMs\*|
|---|:---:|:---:|:---:|---:|
|Cluster nodes | 12 | 32 GB | 128 GB |6|
|Wireguard bastion host| 2 | 4 GB | 8 GB |1|
|Nginx|2|4GB|16 GB|1|

\* Virtual Machines

## Network configuration
The following network configuration is required for the above mentioned nodes.
* Cluster Nodes
  * One internal interface: with internet access and that is on the same network as all the rest of nodes. (Eg: NAT Network)
* Nginx VM
  * One internal interface: that is on the same network as all the rest of nodes.
  * One public interface: Either has a direct public IP, or a firewall rule that forwards traffic on 443/tcp port to this interface ip.
* Wireguard Bastion
  * One internal interface: that is on the same network as all the rest of nodes.
  * One public interface: Either has a direct public IP, or a firewall rule that forwards traffic on 51820/udp port to this interface ip.

## DNS requirements
The following DNS mappings will be required.

| Hostname                | Domain                       | Mapped to |
|-------------------------|------------------------------|---|
| installation-domain     | sandbox.xyz.net              | Internal ip of Nginx Node |
| mosip-api-host          | api.sandbox.xyz.net          | Public ip of Nginx node |
| mosip-api-internal-host | api-internal.sandbox.xyz.net | Internal ip |
| mosip-prereg-host       | prereg.sandbox.xyz.net       | Public ip |
| mosip-activemq-host     | activemq.sandbox.xyz.net     | Internal ip |
| mosip-kibana-host       | kibana.sandbox.xyz.net       | Internal ip |
| mosip-regclient-host    | regclient.sandbox.xyz.net    | Internal ip |
| mosip-admin-host        | admin.sandbox.xyz.net        | Internal ip |
| mosip-minio-host        | minio.sandbox.xyz.net        | Internal ip |
| mosip-kafka-host        | kafka.sandbox.xyz.net        | Internal ip |
| mosip-iam-external-host | iam.sandbox.xyz.net          | Internal ip |
| mosip-postgres-host     | postgres.sandbox.xyz.net     | Internal ip |
| mosip-pmp-host          | pmp.sandbox.xyz.net          | Internal ip |
| mosip-onboarder-host    | onboarder.sandbox.xyz.net    | Internal ip |
| mosip-resident-host     | resident.sandbox.xyz.net     | Public ip of nginx node |
| mosip-idp-host          | idp.sandbox.xyz.net          | Public ip of nginx node |
| mosip-smtp-host         | smtp.sandbox.xyz.net         | Internal ip |

Note: The above table is just a placeholder for hostnames, the actual name itself varies from organisation to organisation.  A sample hostname list is given at [global_configmap.yaml.sample](../global_configmap.yaml.sample) <br/>
Note: Only proceed to DNS mapping after the ingressgateways are installed and the nginx reverse proxy is setup.

## Certificate requirements
* Depending upon the above hostnames, will requires atleast one wildcard SSL certificate. For example; `*.mosip.gov.country`.
* Will need more ssl certificates, for every new level of hierarchy. For example; `*.sandbox1.mosip.example.org`.
