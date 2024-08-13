# Ingress
## Introduction
* Ingress is an API object that manages external access to services within a cluster, typically HTTP and HTTPS traffic.
* Ingress allows to define rules for routing traffic to services based on the URL paths, hostnames, or other criteria.
* Ingress is a powerful feature for managing how external users access your applications running in a Kubernetes cluster.
## Major funtionalities of Ingress
* Path-based Routing: 
  * Defines rules that direct traffic to different services based on the URL path. 
  * For example, traffic to `/api` could go to one service, while `/static` goes to another.
* Host-based Routing: 
  * Routes traffic to different services based on the hostname.
  * For example, traffic to `api.example.com` could be routed to one service, while `web.example.com` is routed to another.
* TLS/SSL Termination: 
  * Ingress can handle SSL/TLS termination for you.
  * Specifies secret that contains the SSL certificate and private key, and the Ingress controller will use it to terminate the SSL connection.
## Supported Ingress
* [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)
* [istio-mesh](https://kubernetes.github.io/ingress-nginx/)
### Setup ingress-nginx
Detailed steps to setup ingress-nginx is mentioned [here](./ingress-nginx/README.md)
### istio-mesh
Detailed steps to setup istio-mesh is mentioned [here](./istio-mesh/README.md)
