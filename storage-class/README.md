# Storge Class
## Introduction
### Storage Class
* A StorageClass provides a way for administrators to describe the classes of storage they offer.
* Different classes might map to quality-of-service levels, or to backup policies, or to arbitrary policies determined by the cluster administrators.
* The Kubernetes concept of a storage class is similar to “profiles” in some other storage system designs.
### StorageClass objects
Each StorageClass contains the fields:
* provisioner : is responsible for the creation of the actual storage resource (e.g., a persistent volume) when a PersistentVolumeClaim (PVC) requests it.
* parameters : The parameters field in a StorageClass allows for fine-tuning of the provisioned storage volumes according to the requirements and capabilities of the underlying storage provider. 
* reclaimPolicy : 
  * The reclaimPolicy in Kubernetes is an important attribute of a PersistentVolume (PV) that dictates what happens to the physical storage resource when the PV is released (i.e., when its associated PersistentVolumeClaim (PVC) is deleted).
  * The reclaimPolicy can be set to one of the following values:
    * Retain: 
      * This policy allows for manual reclamation of the resource.
      * When the PVC is deleted, the PV remains and its status becomes Released.
      * A cluster administrator can manually reclaim the resource, making it available for reuse.
      * Note: 
        * In case of pilot and production it is suggested to change the reclaim policy to `retain`, to avoid pvc getting deleted unintentionally.
        * Or create one more storage class with `reclaimPolicy` with default value as retain and use it for deployments holding crucial non transactional data.
    * Delete: 
      * This policy automatically deletes the associated storage resource when the PVC is deleted.
      * For dynamically provisioned volumes, the underlying storage resource (such as an AWS EBS volume or a GCE PD) will be deleted.
    * Recycle: 
      * This policy is deprecated as of Kubernetes v1.11.
      * It used to delete the contents of the volume and make it available again for a new claim.
      * The recommended approach now is to use external storage providers or scripts for similar functionality.
### Default StorageClass
* StorageClass can be specified as default for k8 cluster.
* When a PVC does not specify a storageClassName, the default StorageClass is used.
* If `storageclass.kubernetes.io/is-default-class` annotation is set to true on more than one StorageClass in k8s cluster, and `PersistentVolumeClaim` is created with no `storageClassName` set, k8s uses the most recently created default StorageClass.
### Volume expansion
* PersistentVolumes can be configured to be expandable.
* This allows you to resize the volume by editing the corresponding PVC object, requesting a new larger amount of storage.
## Storage Class Setup
Repo contains steps to setup below mentioned Storage classes for k8 cluster.
* [NFS](./nfs/README.md)
* [Longhorn](./longhorn/README.md)
* [CEPH CSI](./ceph/README.md)
* [EBS](./ebs/README.md)
* [EFS](./efs/README.md) 
