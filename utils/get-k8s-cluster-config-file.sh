#!/bin/sh

read -p "Provide environment name : " ENV_NAME;

if [ -z "$ENV_NAME" ]; then
    echo "ENVIRONMENT NAME not provided; EXITING";
    exit 1;
fi

FILENAME=~/$ENV_NAME-kube-config-cluster.yml;
INTERFACE_NAME="eth0";
IP_ADDRESS=$( ip addr show $INTERFACE_NAME | grep -w $INTERFACE_NAME | awk 'NR==2{print $2}' | awk -F '/' '{print $1}' );
CERTIFICATE_AUTHORITY=$( cat "/etc/kubernetes/ssl/kube-ca.pem" | base64  | sed -E ':a;N;$!ba;s/\r{0,1}\n//g' )
CLIENT_CERTIFICATE=$( cat "/etc/kubernetes/ssl/kube-controller-manager.pem" | base64  | sed -E ':a;N;$!ba;s/\r{0,1}\n//g' )
CLIENT_KEY=$( cat "/etc/kubernetes/ssl/kube-controller-manager-key.pem" | base64  | sed -E ':a;N;$!ba;s/\r{0,1}\n//g' )

cat <<< "apiVersion: v1
kind: Config
clusters:
- cluster:
    api-version: v1
    certificate-authority-data: $CERTIFICATE_AUTHORITY
    server: \"https://$IP_ADDRESS:6443\"
  name: \"$ENV_NAME\"
contexts:
- context:
    cluster: \"$ENV_NAME\"
    user: \"kube-admin-local\"
  name: \"$ENV_NAME\"
current-context: \"$ENV_NAME\"
users:
- name: \"kube-admin-local\"
  user:
    client-certificate-data: $CLIENT_CERTIFICATE
    client-key-data: $CLIENT_KEY" > "$FILENAME";

echo "INTERFACE NAME : $INTERFACE_NAME";
echo "IP ADDRESS : $IP_ADDRESS";
echo "KUBENETES CLUSTER CONFIG FILE : $FILENAME ";
