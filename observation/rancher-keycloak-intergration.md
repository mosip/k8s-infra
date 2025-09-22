## 5. Observation K8's Cluster Apps Installation

### 5.a. Rancher UI

Rancher provides full CRUD capability of creating and managing kubernetes cluster.

*   Install rancher using Helm, update `hostname` in `rancher-values.yaml` and run the following command to install.

    ```
    cd $K8_ROOT/rancher/rancher-ui
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    helm repo update
    helm install rancher rancher-latest/rancher \
    --version 2.6.9 \
    --namespace cattle-system \
    --create-namespace \
    -f rancher-values.yaml
    ```
*   Login:

    * Connect to the Wireguard. (in case using Windows via WSL, make sute to connect to wireguard server from windows instead of WSL).
    * Open Rancher page.
    * Get Bootstrap password using

    ```
    kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{ .data.bootstrapPassword|base64decode}}{{ "\n" }}'
    ```

> Note: Assign a password. IMPORTANT: makes sure this password is securely saved and retrievable by Admin.

### 5.b. Keycloak

*   Keycloak is an OAuth 2.0 compliant Identity Access Management (IAM) system used to manage the access to Rancher for cluster controls.

    ```
    cd $K8_ROOT/rancher/keycloak
    ./install.sh <iam.host.name>
    ```
* Post installation access the keycloak using `iam.mosip.net` and get the credentials as per the post installation steps defined ![keycloak-access](../../../../_images/keycloak-login.png).

### 5.c. Keycloak - Rancher UI Integration

* Login as `admin` user in Keycloak and make sure `email` and `firstName` fields are populated for the admin user. These are required for Rancher authentication to work properly.
* In Keycloak (in the `master` realm), create a new client with the following values:
  * `Client ID`: `https://<your-rancher-host>/v1-saml/keycloak/saml/metadata`
  * `Client Protocol`: `saml`
  * `Root URL`: _(leave empty)_
  * After saving, configure the client with:
    * `Name`: `rancher`
    * `Enabled`: `ON`
    * `Login Theme`: `keycloak`
    * `Sign Documents`: `ON`
    * `Sign Assertions`: `ON`
    * `Encrypt Assertions`: `OFF`
    * `Client Signature Required`: `OFF`
    * `Force POST Binding`: `OFF`
    * `Front Channel Logout`: `OFF`
    * `Force Name ID Format`: `OFF`
    * `Name ID Format`: `username`
    * `Valid Redirect URIs`: `https://<your-rancher-host>/v1-saml/keycloak/saml/acs`
    * `IDP Initiated SSO URL Name`: `IdPSSOName`
  * Save the client
* In the same client, go to the `Mappers` tab and create the following:
  * **Mapper 1**:
    * `Protocol`: `saml`
    * `Name`: `username`
    * `Mapper Type`: `User Property`
    * `Property`: `username`
    * `Friendly Name`: `username`
    * `SAML Attribute Name`: `username`
    * `SAML Attribute NameFormat`: `Basic`
  * **Mapper 2**:
    * `Protocol`: `saml`
    * `Name`: `groups`
    * `Mapper Type`: `Group List`
    * `Group Attribute Name`: `member`
    * `Friendly Name`: (Leave empty)
    * `SAML Attribute NameFormat`: `Basic`
    * `Single Group Attribute`: `ON`
    * `Full Group Path`: `OFF`
  * Click `Add Builtin` → select all → `Add Selected`
* Download the Keycloak SAML descriptor XML file from:
  * `https://<your-keycloak-host>/auth/realms/master/protocol/saml/descriptor`
*   Generate a self-signed SSL certificate and private key (if not already available):

    ```bash
    openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout myservice.key -out myservice.cert

    ```
*   **Rancher UI Configuration**

    * **In Rancher UI, go to :**

    `Users & Authentication` → `Auth Providers` → `Keycloak (SAML)`

    *   **Configure the fields as follows :**

        `Display Name Field`: `givenName`

        `User Name Field`: `email` or `uid`

        `UID Field`: `username`

        `Groups Field`: `member`

        `Entity ID Field`: (Leave empty)

        `Rancher API Host`: `https://<your-rancher-host>`
    * **Upload the following files:**

    `Private Key`: `myservice.key`

    `Certificate`: `myservice.cert`

    `SAML Metadata XML`: (from the Keycloak descriptor link)

    * Click **Enable** to activate Keycloak authentication.
    * **After successful integration, Rancher users should be able to log in using their Keycloak**

### 5.d. RBAC for Rancher using Keycloak

* For users in Keycloak assign roles in Rancher - **cluster** and **project** roles. Under `default` project add all the namespaces. Then, to a non-admin user you may provide Read-Only role (under projects).
* If you want to create custom roles, you can follow the steps given [here](https://github.com/mosip/k8s-infra/blob/v1.2.0.1/docs/create-custom-role.md).
* Add a member to cluster/project in Rancher:
  * Navigate to RBAC cluster members
  * Add member name exactly as `username` in Keycloak
  * Assign appropriate role like Cluster Owner, Cluster Viewer etc.
  * You may create new role with fine grained acccess control.
* Add group to to cluster/project in Rancher:
  * Navigate to RBAC cluster members
  * Click on `Add` and select a group from the displayed drop-down.
  * Assign appropriate role like Cluster Owner, Cluster Viewer etc.
  * To add groups, the user must be a member of the group.
* Creating a Keycloak group involves the following steps:
  * Go to the "Groups" section in Keycloak and create groups with default roles.
  * Navigate to the "Users" section in Keycloak, select a user, and then go to the "Groups" tab. From the list of groups, add the user to the required group.

# TODO (Under Development)

- [ ] Automate Rancher ↔ Keycloak integration  
- [ ] Define default RBAC policies for new users and groups  
- [ ] Implement centralized role mapping across clusters  
