#!/bin/sh

read -p "Provide environment name : " ENV_NAME;

if [ -z "$ENV_NAME" ]; then
    echo "ENVIRONMENT NAME not provided; EXITING";
    exit 1;
fi

FILENAME=~/$ENV_NAME-kube-config-cluster.yml;
INTERFACE_NAME="eth0";
IP_ADDRESS=$( ip addr show $INTERFACE_NAME | grep -w $INTERFACE_NAME | awk 'NR==2{print $2}' | awk -F '/' '{print $1}' );
CERTIFICATE_AUTHORITY=$( base64 "/etc/kubernetes/ssl/kube-ca.pem" | sed -E ':a;N;$!ba;s/\r{0,1}\n//g' )
CLIENT_CERTIFICATE=$( base64  "/etc/kubernetes/ssl/kube-controller-manager.pem" | sed -E ':a;N;$!ba;s/\r{0,1}\n//g' )
CLIENT_KEY=$( base64 "/etc/kubernetes/ssl/kube-controller-manager-key.pem" | sed -E ':a;N;$!ba;s/\r{0,1}\n//g' )

# copy kube node yaml file
sudo cp "/etc/kubernetes/ssl/kubecfg-kube-node.yaml" "$FILENAME";

sed -i 's/certificate-authority:.*/certificate-authority-data:/g' "$FILENAME";
sed -i 's/client-certificate:.*/client-certificate-data:/g' "$FILENAME";
sed -i 's/client-key:.*/client-key-data:/g' "$FILENAME";

sed -i "s/127.0.0.1/$IP_ADDRESS/g" "$FILENAME";
sed -i "s/\"local\"/\"$ENV_NAME\"/g" "$FILENAME";

sed -i "s/certificate-authority-data:/certificate-authority-data: $CERTIFICATE_AUTHORITY/g" "$FILENAME";
sed -i "s/client-certificate-data:/client-certificate-data: $CLIENT_CERTIFICATE/g" "$FILENAME";
sed -i "s/client-key-data:/client-key-data: $CLIENT_KEY/g" "$FILENAME";

echo "INTERFACE NAME : $INTERFACE_NAME";
echo "IP ADDRESS : $IP_ADDRESS";
echo "CREATED KUBERNETES CLUSTER CONFIG FILE : $FILENAME ";
