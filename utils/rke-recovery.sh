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
echo "Working on Nodes..."
echo 'nodes:' > cluster.yml
kubectl -n kube-system get configmap full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r .desiredState.rkeConfig.nodes | yq -P | sed 's/^/  /' | \
sed -e 's/internalAddress/internal_address/g' | \
sed -e 's/hostnameOverride/hostname_override/g' | \
sed -e 's/sshKeyPath/ssh_key_path/g' >> cluster.yml
echo "" >> cluster.yml

echo "Working on services..."
echo 'services:' >> cluster.yml
kubectl -n kube-system get configmap full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r .desiredState.rkeConfig.services | yq -P | sed 's/^/  /' >> cluster.yml
echo "" >> cluster.yml

echo "Working on network..."
echo 'network:' >> cluster.yml
kubectl -n kube-system get configmap full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r .desiredState.rkeConfig.network | yq -P | sed 's/^/  /' >> cluster.yml
echo "" >> cluster.yml

echo "Working on authentication..."
echo 'authentication:' >> cluster.yml
kubectl -n kube-system get configmap full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r .desiredState.rkeConfig.authentication | yq -P | sed 's/^/  /' >> cluster.yml
echo "" >> cluster.yml

echo "Working on systemImages..."
echo 'system_images:' >> cluster.yml
kubectl -n kube-system get configmap full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r .desiredState.rkeConfig.systemImages | yq -P | sed 's/^/  /' >> cluster.yml
echo "" >> cluster.yml

echo "Building cluster.rkestate..."
kubectl -n kube-system get configmap full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r . > cluster.rkestate

echo "Retrieve kube_config_cluster.yml file"
read -p "Please provide internal IP of node with control plane role" IP_ADDR

if [ -z $IP_ADDR ]; then
  echo "IP address of node with control plane role not provided; EXITING;";
  exit 1;
fi

kubectl --kubeconfig $(docker inspect kubelet --format '{{ range .Mounts }}{{ if eq .Destination "/etc/kubernetes" }}{{ .Source }}{{ end }}{{ end }}')/ssl/kubecfg-kube-node.yaml get configmap -n kube-system full-cluster-state -o json | jq -r .data.\"full-cluster-state\" | jq -r .currentState.certificatesBundle.\"kube-admin\".config | sed -e "/^[[:space:]]*server:/ s_:.*_: \"https://$IP_ADDR:6443\"_" > kube_config_cluster.yml