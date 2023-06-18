# MOSIP installation without public DNS

## Nginx node setup

#### Steps prior to Nginx installation
* Install docker on nginx node.
    * Follow the below steps to install docker on Ubuntu OS. If you prefer to install Docker on an operating system other than Ubuntu, you can refer to the instructions provided [here](https://docs.docker.com/engine/install/#server).
      ```
       sudo apt-get update --fix-missing
       sudo apt install docker.io -y
       sudo systemctl restart docker
      ```
* Generate a self-signed certificate for your domain, such as `*.sandbox.xyz.net`.
    * Create a volume that points to the local directory `/etc/ssl` by executing the provided command:
      ```
      docker volume create --name gensslcerts --opt type=none --opt device=/etc/ssl --opt o=bind
      ```
    * Execute the following command to generate a self-signed SSL certificate.
      Prior to execution, kindly ensure that the environmental variables passed to the OpenSSL Docker container have been properly updated:
      ```
      docker run -it --mount type=volume,src='gensslcerts',dst=/home/mosip/ssl,volume-driver=local \
      -e VALIDITY=700        \
      -e COUNTRY=IN          \
      -e STATE=KAR           \
      -e LOCATION=BLR        \
      -e ORG=MOSIP           \
      -e ORG_UNIT=MOSIP      \
      -e COMMON_NAME=*.sandbox.xyz.net \
      mosipdev/openssl:latest 
      ```

#### Steps while installing Nginx
* Use below mentioned details when prompted in nginx install scripts:
    1. fullChain path: `/etc/ssl/certs/nginx-selfsigned.crt`.
    1. privKey path: `/etc/ssl/private/nginx-selfsigned.key`.

#### Steps after installing Nginx
* Add the below section in the http block in the `/etc/nginx/nginx.conf` file. Update `iam.sandbox.xyz.net`, `<cluster-nginx-internal-ip>` in below block.
  ```
  http{
      server{
         listen <cluster-nginx-internal-ip>:80;
         server_name iam.sandbox.xyz.net;
         location /auth/realms/mosip/protocol/openid-connect/certs {
              proxy_pass                      http://myInternalIngressUpstream;
              proxy_http_version              1.1;
              proxy_set_header                Upgrade $http_upgrade;
              proxy_set_header                Connection "upgrade";
              proxy_set_header                Host $host;
              proxy_set_header                Referer $http_referer;
              proxy_set_header                X-Real-IP $remote_addr;
              proxy_set_header                X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header                X-Forwarded-Proto $scheme;
              proxy_pass_request_headers      on;
              proxy_set_header  Strict-Transport-Security "max-age=0;";
         }
         location / { return 301 https://iam.sandbox.xyz.net; }
      }
  }
  ```
  **Note:** HTTP access is enabled for IAM because MOSIP's keymanager expects to have valid SSL certificates.
            Ensure to use this **only for development purposes**, and it is not recommended to use it in **production environments**.

* Restart nginx service.
  ```
  sudo systemctl restart nginx
  ```

## K8S coredns setup
* Once the cluster is created, we can set up custom DNS for the cluster.
* Check whether coredns pods are up and running in your cluster via the below command:
  ```
  kubectl -n kube-system get pods -l k8s-app=kube-dns
  ```
  output:
  ```
    NAME                      READY   STATUS    RESTARTS   AGE
    coredns-cd565b844-b75zz   1/1     Running   0          7d19h
    coredns-cd565b844-m8lg5   1/1     Running   0          7d19h
  ```
* Update the IP address and domain name in the below DNS hosts template and add it in the coredns configmap `Corefile` key in the `kube-system` namespace.
  ```
   hosts {
     <PUBLIC_IP>    api.sandbox.xyz.net resident.sandbox.xyz.net esignet.sandbox.xyz.net prereg.sandbox.xyz.net healthservices.sandbox.xyz.net
     <INTERNAL_IP>  sandbox.xyz.net api-internal.sandbox.xyz.net activemq.sandbox.xyz.net kibana.sandbox.xyz.net regclient.sandbox.xyz.net admin.sandbox.xyz.net minio.sandbox.xyz.net iam.sandbox.xyz.net kafka.sandbox.xyz.net postgres.sandbox.xyz.net pmp.sandbox.xyz.net onboarder.sandbox.xyz.net smtp.sandbox.xyz.net compliance.sandbox.xyz.net
     fallthrough
   }
  ```
* Update coredns configmap via below command.
  ```
  kubectl -n kube-system edit cm coredns
  ```
  example:
  ![mosip-without-dns-1.png](_images/mosip-without-dns-1.png)
* Check whether the DNS changes are correctly updated in coredns configmap.
  ```
  kubectl -n kube-system get cm coredns -o yaml
  ```
* Restart the `coredns` pod in the `kube-system` namespace.
  ```
  kubectl -n kube-system rollout restart deploy coredns coredns-autoscaler
  ```
* Check status of coredns restart.
  ```
  kubectl -n kube-system rollout status deploy coredns
  kubectl -n kube-system rollout status coredns-autoscaler
  ```

## Update config properties below starting deployment
* Add/ Update the below property in `application-default.properties` and comment on the below property in the `*-default.properties` file in the config repo.
  ```
  mosip.iam.certs_endpoint=http://${keycloak.external.host}/auth/realms/mosip/protocol/openid-connect/certs
  ```
* Add/ Update the below property in the `esignet-default.properties` file in the config repo.
  ```
  spring.security.oauth2.resourceserver.jwt.jwk-set-uri=http://${keycloak.external.host}/auth/realms/mosip/protocol/openid-connect/certs
  ```

## Deployment steps
* While installing a few modules, installation script prompts to check if you have public domain and valid SSL certificates on the server.
  Opt option `n` as we are using self-signed certificates.
  For example:
  ```
  $ ./install.sh
  Do you have public domain & valid SSL? (Y/n) 
   Y: if you have public domain & valid ssl certificate
   n: If you don't have a public domain and a valid SSL certificate. Note: It is recommended to use this option only in development environments.
  ```

## Local/Client side setup
### DNS setup
* Map IP address and domain names to set up DNS in the respective `hosts` file. <br>
  For example: `/etc/hosts` files for Linux machines.
  ```
   <PUBLIC_IP>    api.sandbox.xyz.net resident.sandbox.xyz.net esignet.sandbox.xyz.net prereg.sandbox.xyz.net healthservices.sandbox.xyz.net
   <INTERNAL_IP>  sandbox.xyz.net api-internal.sandbox.xyz.net activemq.sandbox.xyz.net kibana.sandbox.xyz.net regclient.sandbox.xyz.net admin.sandbox.xyz.net minio.sandbox.xyz.net iam.sandbox.xyz.net kafka.sandbox.xyz.net postgres.sandbox.xyz.net pmp.sandbox.xyz.net onboarder.sandbox.xyz.net smtp.sandbox.xyz.net compliance.sandbox.xyz.net
  ```
* Visit https://sandbox.xyz.net on any browser. You should see the landing page.
  In case you are faced with a certificate exception, accept the certificate and proceed because we are using the self-signed certificate.
  So, we have to accept the certificate always.

### Reg-client setup
* Download & unzip reg-client.
* Make sure to have a `Windows` machine.
* Export self-signed certificate from browser to the reg-client directory with name `_.sandbox.xyz.net.cer`.
  ![mosip-without-dns-3.png](_images/mosip-without-dns-3.png)
* Add self-signed certificate to cacerts keystore.
    * Open terminal under reg-client.
    * Update the domain below command and run it on the terminal to a self-signed certificate to cacerts keystore.
      ```
      XXXXX\reg-client> jre\bin\keytool -import -trustcacerts -alias api-internal.sandbox.xyz.net -file %CD%\_.soil.mosip.net.cer -keystore %CD%\jre\lib\security\cacerts -noprompt -storepass changeit
      
      Warning: use -cacerts option to access cacerts keystore
      Certificate was added to keystore
      ```
    * Follow reg-client documentation to proceed further.

### Troubleshooting
* If you are facing an issue in accessing UIs in your browser because of `HTTP Strict Transport Security(HSTS)`, follow the below steps to delete hsts policies for a specific domain.
  * Delete `hsts` security policies for listed domains.
    * open `hsts` setting in any browser example: `chrome://net-internals/#hsts`.
    * Provide domain name `iam.sandbox.xyz.net`and click on `delete`.
      ![mosip-without-dns-2.png](_images/mosip-without-dns-2.png)
    * Repeat the same for other domains.