# Keycloak
## Overview
Keycloak is an OAuth 2.0 compliant Identity Access Management (IAM) system used to manage the access to Rancher for cluster controls.
## Install
* Run the install script to install the keycloak as below:
  ```
  ./install.sh <iam.host.name>
  ```
  eg. ./install.sh iam.xyz.net
* `keycloak_client.json`:  Used to create SAML client on Keycloak for Rancher integration.
## Integrate Keycloak with Rancher UI
* Login as admin user in Keycloak and make sure an email id, and first name field is populated for admin user. This is important for Rancher authentication as given below.
* Enable authentication with Keycloak by performig mentioned [steps](https://ranchermanager.docs.rancher.com/v2.6/how-to-guides/new-user-guides/authentication-permissions-and-global-configuration/authentication-config/configure-keycloak-saml).
* In Keycloak add another Mapper for the rancher client (in Master realm) with following fields:
  * Protocol: saml
  * Name: username
  * Mapper Type: User Property
  * Property: username
  * Friendly Name: username
  * SAML Attribute Name: username
  * SAML Attribute NameFormat: Basic
* Specify the following mappings in Rancher's Authentication Keycloak form:
  * Display Name Field: givenName
  * User Name Field: email
  * UID Field: username
  * Entity ID Field: https://your-rancher-domain/v1-saml/keycloak/saml/metadata
  * Rancher API Host: https://your-rancher-domain
  * Groups Field: member
## RBAC for Rancher using Keycloak
* For users in Keycloak assign roles in Rancher - cluster and project roles.
  * Under `default` project add all the namespaces.
  * For non-admin user you may provide Read-Only or any other available role (under projects).
* Follow [steps](../../docs/create-custom-role.md) to create custom roles.
* Add a member to cluster/project in Rancher:
  * Navigate to RBAC cluster members.
  * Add member `name` exactly as `username` in Keycloak.
  * Assign appropriate role like Cluster Owner, Cluster Viewer etc.
  * You may create new role with fine grained acccess control.
* Add group to to cluster/project in Rancher:
  * Navigate to RBAC cluster members
  * Click on `Add` and select a group from the displayed drop-down.
  * Assign appropriate role like `Cluster Owner`, `Cluster Viewer` etc.
  * To add groups, the user must be a member of the group.
* Creating a Keycloak group involves the following steps:
  * Go to the `Groups` section in Keycloak and create groups with default roles.
  * Navigate to the `Users` section in Keycloak.
  * Select a user.
  * Move to the "Groups" tab. 
  * From the list of groups, add the user to the required group.
