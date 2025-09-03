# Requirements for On-prem Observation Cluster Sandbox
* Listed below are hardware, network and certificate requirements to setup a **Onservation Sandbox** on-prem.
## Hardware requirements
|Purpose|vCPUs|RAM|Storage (SSD) |Number of VMs\*|
|---|:---:|:---:|:---:|---:|
|Cluster nodes | 4 | 16 GB | 32 GB |2|
|Wireguard bastion host| 2 | 4 GB | 8 GB |1|
|Nginx|2|4GB|16 GB|1|
## Network configuration
The following network configuration is required for the above mentioned nodes.
* Cluster Nodes
  * One internal interface: with internet access and that is on the same network as all the rest of nodes. (Eg: NAT Network).
* Nginx VM
  * One internal interface: that is on the same network as all the rest of nodes.
  * One public interface: Either has a direct public IP, or a firewall rule that forwards traffic on 443/tcp port to this interface ip.
* Wireguard Bastion
  * One internal interface: that is on the same network as all the rest of nodes.
  * One public interface: Either has a direct public IP, or a firewall rule that forwards traffic on 51820/udp port to this interface ip.
## DNS requirements
* The following DNS mappings will be required.
|Hostname|Domain|Mapped to|
|--|--|--|
|Observation keycloak host|keycloak.xyz.net|Internal IP of Nginx node|
|Rancher host |rancher.xyz.net|Internal IP of Nginx node|
* Note:
  * The above table is just a placeholder for hostnames, the actual name itself varies from organisation to organisation.
  * Only proceed to DNS mapping after the ingressgateways are installed and the nginx reverse proxy is setup.
## Certificate requirements
* Depending upon the above hostnames, will requires atleast one wildcard SSL certificate. For example; `*.mosip.gov.country`.
