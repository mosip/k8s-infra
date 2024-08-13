# Istio

## Install
* Install `istioctl` as given [here](https://istio.io/latest/docs/setup/getting-started/#download)
* `istioctl` version should be 1.22.0.
* Run
  ```bash
  ./install.sh
  ```
* Load Balancers setup for istio-mesh.
  * The above istio installation will automatically spawn an [Internal AWS Network Load Balancer (L4)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-network-load-balancer.html).
  * same can be checked as well:
    ```
    kubectl -n istio-system get svc
    ```
  * Check the spawned Laodbalancers in AWS console as well.
  * TLS termination is supposed to be on LB. So all our traffic coming from ingress shall be HTTP.
  * Obtain AWS TLS certificate as given [here](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html).
  * Add the certificates and 443 access to the LB listener.
  * Update listener TCP->443 to TLS->443 and point to the certificate of domain name that belongs to your cluster.
  * Forward TLS->443 listner traffic to target group that corresponds to listener on port 80 of respective Loadbalancers.
  * This is because after TLS termination the protocol is HTTP so we must point LB to HTTP port of ingress controller.
  * Update health check ports of LB target groups to node port corresponding to port 15021. You can see the node ports using:
    ```
    kubectl -n istio-system get svc
    ```
  * Enable Proxy Protocol v2 on target groups.
  * Make sure all subnets are included in Availability Zones for the LB. Description --> Availability Zones --> Edit Subnets.
  * Make sure to delete the listeners for port 80 and 15021 from each of the loadbalancers as we restrict unsecured port 80 access over http.
* DNS Mapping:
  * Initially all the services will be accesible only over the internal channel.
  * Point all your domain names to internal LoadBalancers DNS/IP intially till testing is done.
  * On AWS this may be done on Route 53 console.
  * After Go live decision enable public access.
* Check Overall if nginx and istio wiring is set correctly
  * Install httpbin: 
    * This utility docker returns http headers received inside the cluster.
    * Use it for general debugging - to check ingress, headers etc.
      ```
      cd ../../../utils/httpbin
      ./install.sh
      ```
    * To see what's reaching httpbin (example, replace with your domain name):
      ```
      curl https://api-internal.sandbox.xyz.net/httpbin/get?show_env=true
      ```
    * Once public access is enabled also check this:
      ```
      curl https://api.sandbox.xyz.net/httpbin/get?show_env=true
      ```
## Istio injection
* To enable Istio injection in a namespace:
  ```kubectl
  kubectl label ns <namespace> istio-injection=enabled --overwrite
  ```
## Uninstall
* This is not part of regular installation. Perform this step only while removing Istio components.
  ```bash
  ./delete.sh
  ```
