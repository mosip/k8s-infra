#!/bin/sh
# Use this script only when you already have Istio (instead of Nginx Ingress) on your cluster.
# Usage: ./install.sh <rancher host name>
#   rancher host name: E.g. rancher.xyz.net
# Review ingress control name in gateway.yaml
NS=cattle-system
echo Install istio addons
helm -n $NS install istio-addons chart/istio-addons --set rancherHost=$1
