# Istio

## Install
* Install `istioctl` as given [here](https://istio.io/latest/docs/setup/getting-started/#download)
* `istioctl` version should be 1.22.0.
* Run
  ```bash
  ./install.sh
  ```
* Point your domain name to the load balancer as given [here](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-elb-load-balancer.html)
* Make sure load balancer points to health check ports for all health checks.  Health check ports used by Istio is given [here](https://istio.io/latest/docs/ops/deployment/requirements/#ports-used-by-istio). You need to point LB to *node port* corresponding to the health check port (15021) which may be obtained as below:
    ```kubectl
    $ kubectl -n istio-system get svc istio-ingressgateway
    $ kubectl -n istio-system get svc istio-ingressgateway-internal
    ```
* To check the connections you may install [httpbin](../../../utils/httpbin)

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
