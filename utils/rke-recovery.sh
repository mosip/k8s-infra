#!/bin/bash
echo Installing pre-requisites
echo Installing snapd
sudo apt install snapd -y
echo Installing yq utility
sudo snap install yq
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
