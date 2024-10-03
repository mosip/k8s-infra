# Istio service Mesh
## Introduction
### Oveview
* Istio is a powerful open-source service mesh that provides a way to control how microservices share data with one another.
* Istio manages traffic between microservices, enforces security policies, and provides powerful observability and tracing capabilities.
* Istio is designed to work with Kubernetes, although it can be used with other environments as well.
### Key Components of Istio
* Envoy Proxy:
  * Envoy is deployed as a sidecar proxy alongside each microservice in the mesh.
  * This means every service-to-service communication goes through an Envoy proxy, allowing Istio to manage and observe traffic.
  * Envoy handles tasks like load balancing, retries, circuit breaking, and fault injection.
* Istiod (Control Plane):
  * Istiod manages and configures the Envoy proxies to route traffic, apply policies, and enforce security.
  * Istiod keeps track of the services in the mesh and their endpoints.
  * Ensures that policies related to traffic, security, and telemetry are applied consistently across the mesh.
  * Provides an interface for managing Istio’s configuration (e.g., routing rules, security policies).
* IstioOperator:
  * Istio operators are Kubernetes operators that manage the installation, configuration, and lifecycle of Istio.
  * Istio operators simplify the complex task of managing Istio by automating various aspects.
  * Allows to declaratively configure, manage and upgrade Istio components consistently across different environments.
* Gateway:
  * Gateways are used primarily to manage external traffic entering the mesh (e.g., from outside the Kubernetes cluster).
  * Gateway configures HTTP/HTTPS/TCP traffic entering the mesh.
  * Responsible for defining the ports that should be exposed, the protocols that should be supported, and any TLS settings.
  * Gateways can handle routing based on HTTP attributes like host, URI, and headers, allowing for advanced traffic management at the edge of the mesh.
  * Gateways exposes selected services to external traffic, which is otherwise isolated within the mesh.
* VirtualService:
  * VirtualService defines how requests for a service are routed within the mesh. 
  * VirtualService controls the routing of traffic once it is inside the mesh, allowing you to define rules such as traffic splitting, retries, timeouts, and fault injection.
  * VirtualServices allows to define routing rules based on conditions like host, path, or header to determine how traffic will be routed to different versions of a service (e.g., for canary deployments).
  * VirtualServices can specify retry policies and timeouts to handle transient failures in the mesh.
* AuthorizationPolicies:
  * AuthorizationPolicies are used to control role-based access to services within the service mesh. 
  * Policies allows to define fine-grained access control rules, specifying which users or services can access certain resources, and under what conditions.
  * Authorization policies are part of Istio's security features, which also include authentication and mutual TLS (mTLS).
  * It can also define access control based on attributes such as request methods, paths, or source IPs.
  * Policies can be applied at different levels of granularity, such as the entire mesh, specific namespaces, or individual workloads.
  * Authorization policies can specify conditions under which access is granted, such as requiring specific headers, tokens, or other request attributes.
  * Creates both allow and deny rules to control what is explicitly permitted or forbidden.
## Install istio in k8 cluster
* Depending upon the ways of exposing the services to external traffic, istio can be deployed in multiple ways.
* Most common methods are using `NodePort` and `LoadBalancer` service types.
  * Expose as NodePort:
    * NodePort exposes istio mesh on a specific port on each node of k8 cluster.
    * External traffic can be directed to any node's IP address, along with the NodePort, to reach the Istio mesh.
    * Suitable for on-premises or bare-metal Kubernetes clusters nothaving loadbalancers.
  * Expose as Loadbalancer:
    * LoadBalancer is typically used in cloud environments (e.g., AWS, GCP, Azure).
    * It automatically provisions an external load balancer, which forwards traffic to the Istio mesh.
    * Simplifies SSL management and DNS configuration.
    * Fully integrates with cloud provider features, such as auto-scaling and health checks.
    * Automatically provides a single external IP address or DNS name for the Ingress.
* Deploy istio-mesh as [NodePort](./nodeport/README.md).
* Deploy istio-mesh as [loadbalancer](./loadbalancer/README.md).
