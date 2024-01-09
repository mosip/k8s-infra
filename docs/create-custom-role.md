# Create a custom role on the rancher

## Steps to create a new role
1. Login to `rancher UI` ---> select `≡` icon.
1. Select `Users & Authentication` ---> `Roles` ---> `Cluster`. 
1. Click on `Create Cluster Role` to create a new role for clusters.
1. Provide a unique role name `Name`. 
1. Set `Cluster Creator Default` to `No` and Set `Locked` to `No`.
1. Select the `Grant Resources` option ---> click on `Add Resource`.
   1. Select a set of operations from the `verbs` section to allow a role to perform the operations on the resource.
   1. Select `Resource` and `API Groups`.
1. If you want to inherit existing roles, Select `Inherit From` option ---> click on `Add Resource` to add a new resource ---> Select Role.


## Create viewAllDeletePod role

`viewAllDeletePod` role: view all resources and delete only pod.

1. Login to `rancher UI` ---> select `≡` icon.
1. Select `Users & Authentication` ---> `Roles` ---> `Cluster`.
1. Click on `Create Cluster Role` to create a new role for clusters.
1. Provide a unique role name `viewAllDeletePod`.
1. Set `Cluster Creator Default` to `No` and Set `Locked` to `No`.
1. Select the `Grant Resources` option ---> click on `Add Resource`.
   1. Select below mentioned `verbs`, `resources`, and `API Groups`.

      | Verbs            | Resource | Non-Resource URLs | API Groups          |
      |----------|-------------------|---------------------|---------------------|
      | get, list, watch | *        |                   |                     |
      | delete           | pods     |                   |                     |
      | get, list, watch | *        |                   | networking.istio.io |
      | get, list, watch | *        |                   | security.istio.io   |

1. Inherit below mentioned roles, Select `Inherit From` option ---> click on `Add Resource` to add a new resource ---> Select Role.
   ```
   View Ingress
   View Monitoring
   View Volumes
   View Nodes
   View Services
   View Config Maps
   View Secrets
   View Service Accounts
   View Cluster Catalogs
   ```

## Create read-only role

`read-only` role: view all resources excluding secrets.

1. Login to `rancher UI` ---> select `≡` icon.
1. Select `Users & Authentication` ---> `Roles` ---> `Cluster`.
1. Click on `Create Cluster Role` to create a new role for clusters.
1. Provide a unique role name `read-only`.
1. Set `Cluster Creator Default` to `No` and Set `Locked` to `No`.
1. Inherit below mentioned roles, Select `Inherit From` option ---> click on `Add Resource` to add a new resource ---> Select Role.
   ```
   View Ingress
   View Monitoring
   View Volumes
   View Nodes
   View Services
   View Config Maps
   View Service Accounts
   View Cluster Catalogs
   View Cluster Members
   Project Monitoring View Role
   Read-only
   ```

## Create read-only-delete-pod role

`read-only-delete-pod` role: view all resources, delete only pod and exclude secrets.

1. Login to `rancher UI` ---> select `≡` icon.
1. Select `Users & Authentication` ---> `Roles` ---> `Cluster`.
1. Click on `Create Cluster Role` to create a new role for clusters.
1. Provide a unique role name `read-only-delete-pod`.
1. Set `Cluster Creator Default` to `No` and Set `Locked` to `No`.
1. Select the `Grant Resources` option ---> click on `Add Resource`.
    1. Select below mentioned `verbs`, `resources`, and `API Groups`.

       | Verbs            | Resource | Non-Resource URLs | API Groups         |
              |----------|-------------------|---------------------|---------------------|
       | delete           | pods     |                   |                    |


1. Inherit below mentioned roles, Select `Inherit From` option ---> click on `Add Resource` to add a new resource ---> Select Role.
   ```
   View Ingress
   View Monitoring
   View Volumes
   View Nodes
   View Services
   View Config Maps
   View Service Accounts
   View Cluster Catalogs
   Project Monitoring View Role
   Read-only
   ```

## Create edit-all-no-secrets role

`edit-all-no-secrets` role: full access to cluster excluding secrets.

1. Login to `rancher UI` ---> select `≡` icon.
1. Select `Users & Authentication` ---> `Roles` ---> `Cluster`.
1. Click on `Create Cluster Role` to create a new role for clusters.
1. Provide a unique role name `edit-all-no-secrets`.
1. Set `Cluster Creator Default` to `No` and Set `Locked` to `No`.
1. Select the `Grant Resources` option ---> click on `Add Resource`.
    1. Select below mentioned `verbs`, `resources`, and `API Groups`.

       | Verbs            | Resource | Non-Resource URLs | API Groups |
              |----------|-------------------|---------------------|---------------------| 
       | create, delete, get, list, watch, patch, update | Gateways |                 | *          |
       | create, delete, get, list, watch, patch, update | Virtualservices |                 | *          |


1. Inherit below mentioned roles, Select `Inherit From` option ---> click on `Add Resource` to add a new resource ---> Select Role.
   ```
   Manage Worloads
   Manage Config Maps
   Manage Ingress
   Manage Service Accounts
   Manage Service
   Mamage Volumes
   View Ingress
   View Monitoring
   View Volumes
   View Nodes
   View Services
   View Config Maps
   View Service Accounts
   View Cluster Catalogs
   Project Monitoring View Role
   Read-only
   ```
   