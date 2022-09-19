#!/bin/sh
# Patch notification alerts 

echo Patching alert manager secrets 
kubectl patch secret alertmanager-rancher-monitoring-alertmanager -n cattle-monitoring-system  --patch="{\"data\": { \"alertmanager.yaml\": \"$(cat ./alertmanager.yaml |base64 |tr -d '\n' )\" }}"
echo Regenerating secrets
kubectl delete secret alertmanager-rancher-monitoring-alertmanager-generated -n cattle-monitoring-system
echo Adding cluster name
kubectl patch Prometheus rancher-monitoring-prometheus -n cattle-monitoring-system --patch-file patch-cluster-name.yaml --type=merge
echo Applying custom alerts
kubectl apply -f custom-alerts/ 
