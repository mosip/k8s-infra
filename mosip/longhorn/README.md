# Longhorn Persistence Storage

## Introduction
[Longhorn](https://longhorn.io) is a persistant storage provider that installs are storage class `longhorn` on the cluster.

## Prerequisites
```sh
./pre_install.sh
```

## Longhorn
1. Install using Rancher UI as given [here](https://longhorn.io/docs/latest/deploy/install/install-with-rancher/).
1. Select Chart Version `100.2.2+up1.3.1` from Rancher console -> _Apps & Marketplaces_.
1. In Helm options of Longhorn, set the replicas for stroage class appropriately. For sandbox, replica of 2 would suffice otherwise storage consumption will be very high. For production, keep the default count.

 <img src="../../docs/_images/storage-class-replicas.png" width="500">
 
1. Set the following parameters under _Edit YAML_ of Helm install: 
    ```
    guaranteedEngineManagerCPU: 5
    guaranteedReplicaManagerCPU: 5
    ```
 
  <img src="../../docs/_images/longhorn-1.png" width="500">

  <img src="../../docs/_images/longhorn-2.png" width="500">

Here the value "5" means 5% of total availalbe node CPU is allocated to **each** `instance-manager` pod in `longhorn-system` namespace. This value should be ok for sandbox and pilot but may have to increased to default "12" for production. The value can also be updated on Longhorn UI after installation.

  <img src="../../docs/_images/longhorn-3.png" width="500">

1. For cloud-native install disable default storage class flag. This will ensure that cloud providers' storage class shall be used as default. 
	```
	$ kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
	```
1. Access Longhorn dashboard from Rancher.
1. Review the "Reserved" space shown on Longhorn dashboard. This much disk space is not used by Longhorn. If the node storage is not used for any other purpose than MOSIP functionality, you may reduced the reserved space on every node by going to Node tab --> menu for each node on the right --> Edit node and disk --> Storage Reserved.

## Backup
For some basic tests and, how to setup an AWS S3 backupstore in Longhorn, refer [docs/longhorn-backupstore-and-tests.md](../../docs/longhorn-backupstore-and-tests.md).
