# Install Istio 
## Install
* Install `istioctl` as given [here](https://istio.io/latest/docs/setup/getting-started/#download)
* Istioctl version 1.22.0.
* Execute
```bash
./install.sh
```
## Istio injection
To enable Istio injection in a namespace:
```kubectl
kubectl label ns <namespace> istio-injection=enabled --overwrite
```
## Uninstall
This is not part of regular installation. Perform this step only while removing Istio components.
```bash
./delete.sh
```
## Install Kiali 
* Install `istioctl` as given [here](https://istio.io/latest/docs/setup/getting-started/#download)
* Istioctl version 1.22.0.
* Execute
  ```bash
  curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.0 TARGET_ARCH=x86_64 sh -
  ```
* Navigate to the Istio package directory:
  ```bash
  cd istio-1.22.0
  ```
* Install Kiali and Prometheus using the sample addons:
  ```kubectl
  kubectl apply -f samples/addons/kiali.yaml
  kubectl apply -f samples/addons/prometheus.yaml
  ```
