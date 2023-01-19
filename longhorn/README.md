# Longhorn Persistence Storage

## Introduction
[Longhorn](https://longhorn.io) is a persistant storage provider that installs are storage class `longhorn` on the cluster.

## Prerequisites
```sh
./pre_install.sh
```

## Longhorn

#### Install Longhorn via helm
1. PV replica count is set to 1. Set the replicas for the storage class appropriately.
   ```
   persistence.defaultClassReplicaCount=1
   defaultSettings.defaultReplicaCount=1
   ```
1. The value "5" means 5% of the total available node CPU is allocated to **each** `instance-manager` pod in the `longhorn-system` namespace.
   This value should be fine for sandbox and pilot but you may have to increase the default to "12" for production.
   The value can be updated on Longhorn UI after installation.
   ```
   guaranteedEngineManagerCPU: 5
   guaranteedReplicaManagerCPU: 5     
   ```
1. Run `install.sh` to install longhorn.
   ```sh
   ./install.sh
   ```
1. For cloud-native installation, disable the default storage class flag. 
   This will ensure that the cloud providers' storage class shall be used as default.
   ```
   kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
   ```
1. Access the Longhorn dashboard from Rancher.
1. Review the `Reserved` space shown on the Longhorn dashboard.
   If the node storage is not used for any other purpose other than MOSIP functionality, you may reduce the reserved space on every node by going to the Node tab --> menu for each node on the right --> Edit node and disk --> Storage Reserved.

## Backup
For some basic tests and, how to setup an AWS S3 backupstore in Longhorn, refer [docs/longhorn-backupstore-and-tests.md](../../docs/longhorn-backupstore-and-tests.md).

## Update multipath.conf file by running below script after installation of longhorn, so it will add a section to avoid multipath PVC issues in the environment. 
   ```
   ansible-playbook -i hosts.ini multipath-conf.yaml
   ```