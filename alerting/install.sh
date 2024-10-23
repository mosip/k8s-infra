#!/bin/bash
# Patch notification alerts 

NS=cattle-monitoring-system

function installing_alerting() {
  echo Patching alert manager secrets
  kubectl patch secret alertmanager-rancher-monitoring-alertmanager -n $NS  --patch="{\"data\": { \"alertmanager.yaml\": \"$(cat ./alertmanager.yaml |base64 |tr -d '\n' )\" }}"
  echo Regenerating secrets
  kubectl delete secret alertmanager-rancher-monitoring-alertmanager-generated -n $NS
  echo Adding cluster name
  kubectl patch Prometheus rancher-monitoring-prometheus -n $NS --patch-file patch-cluster-name.yaml --type=merge
  echo Applying custom alerts
  kubectl apply -f custom-alerts/
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_alerting   # calling function