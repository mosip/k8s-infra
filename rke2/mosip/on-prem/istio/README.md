# Istio

## Install
* Install `istioctl` as given [here](https://istio.io/latest/docs/setup/getting-started/#download)
* Run
```
./install.sh
```

## Istio injection
To enable Istio injection in a namespace:
```
kubectl label ns <namespace> istio-injection=enabled --overwrite
```

## Uninstall
This is not part of regular installation. Perform this step only while removing Istio components.
```
./delete.sh
```

## Install Kiali 
Add kiali repo
```
helm repo add kiali https://kiali.org/helm-charts
```
Install
```
helm install \
    --set clusterRoleCreator=true \
    --set external_services.prometheus.url="http://prometheus-operated.cattle-monitoring-system:9090"     \
    --set external_services.prometheus.custom_metrics_url="http://rancher-monitoring-prometheus.cattle-monitoring-system.svc:9090" \
    --set external_services.grafana.in_cluster_url="http://rancher-monitoring-grafana.cattle-monitoring-system.svc:80" \
    --set external_services.grafana.url="http://rancher-monitoring-grafana.cattle-monitoring-system.svc:80" \
    --set auth.strategy=anonymous \
    --namespace istio-system \
    kiali-server \
    kiali/kiali-server
```
