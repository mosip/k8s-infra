#!/usr/bin/env bash
# ./install.sh installs nginx server.

  if [ -z "$rancher_nginx_ip" ]; then
    echo -en "=====>\n The following internal ip will have to be DNS-mapped to rancher.xyz.net and iam.xyz.net.\n"
    echo -en "Give the internal interface ip of this node here. Run \`ip a\` to get all the interface addresses (without any whitespaces) : "
    read rancher_nginx_ip
  fi &&
  if [ -z "$rancher_nginx_certs" ]; then
    echo -en "=====>\nGive path for SSL Certificate for rancher.xyz.net (without any whitespaces) : "
    read rancher_nginx_certs
    rancher_nginx_certs=$(sed 's/\//\\\//g' <<< $rancher_nginx_certs)
  fi &&
  if [ -z "$rancher_nginx_cert_key" ]; then
    echo -en "=====>\nGive path for SSL Certificate Key for rancher.xyz.net (without any whitespaces) : "
    read rancher_nginx_cert_key
    rancher_nginx_cert_key=$(sed 's/\//\\\//g' <<< $rancher_nginx_cert_key)
  fi &&
  if [ -z "$rancher_cluster_node_ips" ]; then
    echo -en "=====>\nGive list of ips of all nodes in the rancher cluster (without any whitespaces, comma seperated) : "
    read rancher_cluster_node_ips
  fi &&
  if [ -z "$rancher_ingress_nodeport" ]; then
    unset to_replace
    rancher_ingress_nodeport="30080"
    echo -en "=====>\nGive nodeport of the ingresscontroller of rancher cluster (without any whitespaces) (default is 30080) : "
    read to_replace
    rancher_ingress_nodeport=${to_replace:-$rancher_ingress_nodeport}
  fi &&

# Configurig and installing nginx
  apt install -y nginx &&
  upstream_servers="" &&
  for ip in $(sed "s/,/\n/g" <<< $rancher_cluster_node_ips); do
    upstream_servers="${upstream_servers}server ${ip}:${rancher_ingress_nodeport};\n\t\t"
  done &&
  cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig &&
  cp nginx.conf.sample /etc/nginx/nginx.conf &&
  sed -i "s/<rancher-lb-ip>/$rancher_nginx_ip/g" /etc/nginx/nginx.conf &&
  sed -i "s/<rancher-ssl-certificate>/$rancher_nginx_certs/g" /etc/nginx/nginx.conf &&
  sed -i "s/<rancher-ssl-certificate-key>/$rancher_nginx_cert_key/g" /etc/nginx/nginx.conf &&
  sed -i "s/<rancher-nodeport-of-all-nodes>/$upstream_servers/g" /etc/nginx/nginx.conf &&
  systemctl restart nginx &&
  echo "Nginx Installation succesful"
