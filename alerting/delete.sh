#!/bin/bash
# Delete notification alerts

function installing_alerting() {
  echo Deleting custom alerts
  kubectl delete -f custom-alerts/

  echo Removing patch from Prometheus
  kubectl patch Prometheus rancher-monitoring-prometheus -n cattle-monitoring-system --patch-file patch-cluster-name.yaml --type=merge

  echo Deleting generated alert manager secrets
  kubectl delete secret alertmanager-rancher-monitoring-alertmanager -n cattle-monitoring-system
  kubectl delete secret alertmanager-rancher-monitoring-alertmanager-generated -n cattle-monitoring-system

  echo Done deleting resources
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_alerting   # calling function