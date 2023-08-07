#!/bin/bash
echo Installing pre-requisites
echo Installing snapd
sudo apt install snapd -y
echo Installing yq utility
sudo snap install yq
echo Installing jy utility
sudo apt install jq -y
echo Installing kubectl tool
curl -LO "https://dl.k8s.io/release/v1.22.9/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /bin/kubectl

echo "Building cluster.yml..."
kubectl -n kube-system get configmap full-cluster-state -o json| jq -r .data.\"full-cluster-state\" | jq -r .desiredState.rkeConfig | yq -P > cluster.yml

echo "Building cluster.rkestate..."
kubectl -n kube-system get configmap full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r . > cluster.rkestate

echo "Retrieve kube_config_cluster.yml file"
read -p "Please provide internal IP of node with control plane role" IP_ADDR

if [ -z $IP_ADDR ]; then
  echo "IP address of node with control plane role not provided; EXITING;";
  exit 1;
fi

kubectl --kubeconfig $(docker inspect kubelet --format '{{ range .Mounts }}{{ if eq .Destination "/etc/kubernetes" }}{{ .Source }}{{ end }}{{ end }}')/ssl/kubecfg-kube-node.yaml get configmap -n kube-system full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r .currentState.certificatesBundle.\"kube-admin\".config | sed -e "/^[[:space:]]*server:/ s_:.*_: \"https://$IP_ADDR:6443\"_" > kube_config_cluster.yml