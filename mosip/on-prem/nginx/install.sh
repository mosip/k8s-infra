#!/usr/bin/env bash
# Script to configure and install Nginx with public and private interfaces
# Usage: ./install.sh.


  if [ -z "$cluster_nginx_internal_ip" ]; then
    echo -en "=====>\nThe following internal ip will have to be DNS-mapped to all internal domains from you global_configmap.yaml. Ex: api-internal.sandbox.xyz.net, iam.sandbox.xyz.net, etc.\n"
    echo -en "Give the internal interface ip of this node here. Run \`ip a\` to get all the interface addresses (without any whitespaces) : "
    read cluster_nginx_internal_ip
  fi &&
  if [ -z "$cluster_nginx_public_ip" ]; then
    echo -en "=====>\nThis nginx's public ip will have to be DNS-mapped to all public domains from you global_configmap.yaml. Ex: api.sandbox.xyz.net, prereg.sandbox.xyz.net, etc.\nThe above mentioned nginx's public ip might be different from this nginx machine's public interface ip, if you have provisioned public ip seperately that might be forwarding traffic to this interface ip.\n"
    echo -en "Give the public interface ip of this node here. Run \`ip a\` to get all the interfaces, In case not exposing api's to public give private ip only. : "
    read cluster_nginx_public_ip
  fi &&
  if [ -z "$cluster_public_domains" ]; then
    echo -en "=====>\nGive list of (comma seperated) publicly exposing domain names (without any whitespaces). Ex: api.sandbox.xyx.net, prereg.sandbox.xyz.net, resident.sandbox.xyz.net, idp.sandbox.xyz.net etc : "
    read cluster_public_domains
  fi &&
  if [ -z "$cluster_nginx_certs" ]; then
    echo -en "=====>\nGive path for SSL Certificate (fullchain.pem) for sandbox.xyz.net (without any whitespaces) : Ex: /etc//letsencrypt/live/sandbox.xyz.net/fullchain.pem"
    read cluster_nginx_certs
    cluster_nginx_certs=$(sed 's/\//\\\//g' <<< $cluster_nginx_certs)
  fi &&
  if [ -z "$cluster_nginx_cert_key" ]; then
    echo -en "=====>\nGive path for SSL Certificate Key (privkey.pem) for sandbox.xyz.net (without any whitespaces): Ex: /etc/letsencrypt/live/sandbox.xyz.net/privkey.pem : "
    read cluster_nginx_cert_key
    cluster_nginx_cert_key=$(sed 's/\//\\\//g' <<< $cluster_nginx_cert_key)
  fi &&
  if [ -z "$cluster_node_ips" ]; then
    echo -en "=====>\nGive list of (comma seperated) ips of all nodes in the mosip cluster (without any whitespaces) : "
    read cluster_node_ips
  fi &&
  if [ -z "$cluster_ingress_public_nodeport" ]; then
    unset to_replace
    cluster_ingress_public_nodeport="30080"
    echo -en "=====>\nGive nodeport of http port of the mosip cluster public ingressgateway (without any whitespaces) (default is 30080) : "
    read to_replace
    cluster_ingress_public_nodeport=${to_replace:-$cluster_ingress_public_nodeport}
  fi &&
  if [ -z "$cluster_ingress_internal_nodeport" ]; then
    unset to_replace
    cluster_ingress_internal_nodeport="31080"
    echo -en "=====>\nGive nodeport of http port of the mosip cluster internal ingressgateway (without any whitespaces) (default is 31080) : "
    read to_replace
    cluster_ingress_internal_nodeport=${to_replace:-$cluster_ingress_internal_nodeport}
  fi &&
  if [ -z "$cluster_ingress_postgres_nodeport" ]; then
    unset to_replace
    cluster_ingress_postgres_nodeport="31432"
    echo -en "=====>\nGive nodeport of postgres port of the mosip cluster internal ingressgateway (without any whitespaces) (default is 31432) : "
    read to_replace
    cluster_ingress_postgres_nodeport=${to_replace:-$cluster_ingress_postgres_nodeport}
  fi &&
  if [ -z "$cluster_ingress_activemq_nodeport" ]; then
    unset to_replace
    cluster_ingress_activemq_nodeport="31616"
    echo -en "=====>\nGive nodeport of activemq port of the mosip cluster internal ingressgateway (without any whitespaces) (default is 31616) : "
    read to_replace
    cluster_ingress_activemq_nodeport=${to_replace:-$cluster_ingress_activemq_nodeport}
  fi &&

# Configuring and installing nginx
  apt install -y nginx &&
  upstream_server_internal="" &&
  for ip in $(sed "s/,/\n/g" <<< $cluster_node_ips); do
    upstream_server_internal="${upstream_server_internal}server ${ip}:${cluster_ingress_internal_nodeport};\n\t\t"
  done &&
  upstream_server_public="" &&
  for ip in $(sed "s/,/\n/g" <<< $cluster_node_ips); do
    upstream_server_public="${upstream_server_public}server ${ip}:${cluster_ingress_public_nodeport};\n\t\t"
  done &&
  upstream_server_postgres="" &&
  for ip in $(sed "s/,/\n/g" <<< $cluster_node_ips); do
    upstream_server_postgres="${upstream_server_postgres}server ${ip}:${cluster_ingress_postgres_nodeport};\n\t\t"
  done &&
  upstream_server_activemq="" &&
  for ip in $(sed "s/,/\n/g" <<< $cluster_node_ips); do
    upstream_server_activemq="${upstream_server_activemq}server ${ip}:${cluster_ingress_activemq_nodeport};\n\t\t"
  done &&
  for domain in $(sed "s/,/\n/g" <<< $cluster_public_domains); do
    upstream_public_domain_names="${upstream_public_domain_names} ${domain}"
  done &&
  cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig &&
  cp nginx.conf.sample /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-nodeport-public-of-all-nodes>/$upstream_server_public/g" /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-nodeport-internal-of-all-nodes>/$upstream_server_internal/g" /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-ssl-certificate>/$cluster_nginx_certs/g" /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-ssl-certificate-key>/$cluster_nginx_cert_key/g" /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-nginx-internal-ip>/$cluster_nginx_internal_ip/g" /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-nginx-public-ip>/$cluster_nginx_public_ip/g" /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-nodeport-postgres-of-all-nodes>/$upstream_server_postgres/g" /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-nodeport-activemq-of-all-nodes>/$upstream_server_activemq/g" /etc/nginx/nginx.conf &&
  sed -i "s/<cluster-public-domain-names>/$upstream_public_domain_names/g" /etc/nginx/nginx.conf &&
  systemctl restart nginx &&
  echo "Nginx installed succesfully."
