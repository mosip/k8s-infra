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
