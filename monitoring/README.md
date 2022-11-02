# Cluster Monitoring

## Install
Prometheus and Graphana tools are used to monitor the cluster. Install as given below: 
1. Select 'Monitoring' App from  Rancher console -> _Apps & Marketplaces_.
1. Select Chart Version `100.1.3+up19.0.3` from dropdown in Rancher console -> _Apps & Marketplaces_.
1. In Helm options, open the YAML file and disable Nginx Ingress. 

    <img src="../docs/_images/ingress-disable.png" width="300">

1. Click on 'Install'.

## Prometheus
All MOSIP modules have been configured to let Prometheus scrape metrics.

## Grafana
To load a new dashboards to Grafana, sign in with user and password from `rancher-monitoring-grafana` in `cattle-monitoring-system` namespace of Rancher cluster.

Important default dashboards:
|Grafana dashboard|Description|
|---|---|
|Rancher/Cluster (Nodes)|Consolidated view of all nodes|
|Rancher/Node|View of each node|
|Kubernetes/Pesistent Volumes|Storage consumption per PV|
|Kubernetes/Compute Resources/Workload|Resources per deployment/statefulset|
|Kubernetes/Compute Resources/Cluster|Resources namespace wise|

To see JVM stats you may import chart number `14430` in Grafana dashboard.

## JVM stats 
MOSIP pods make JVM stats availalbe for Prometheus to scrape the pods. The typical endpoint looks like
`<base url>/actuator/prometheus`. The scrapping is enabled via module Helm chart (see `metrics` section of `values.yaml`).

A sample of metrics that is pulled by Prometheus is given in [`pod-jvm-scraped-metrics-sample.txt`](./pod-jvm-scraped-metrics-sample.txt)

## Inodes
To see free inodes on a particular node, login to the node an run 
```
df -ih
```
