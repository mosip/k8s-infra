# Resize Existing PVC Storage

## Resize
To resize existing PVC storage, follow the below procedure:
1. Set Variables for resource.
   ```
   NS=<namespace>
   RESOURCE=<resourceName>           ## deployment / statefulset etc
   RESOURCE_NAME=<resourceName>      ## deployment name / statefulset name
   ```
   eg: 
   ```
   NS=minio
   RESOURCE=deployment
   RESOURCE_NAME=minio
   ```
2. Set `resource` replicas to zero (0).
   ```
   kubectl -n $NS scale --replicas=0 $RESOURCE $RESOURCE_NAME
   ```
3. Get PV name from PVC
   ```
   PV_NAME=$( kubectl -n $NS get pvc $RESOURCE_NAME | awk 'NR>1{print $3}' )
   ```
4. Resize PV size `spec.capacity.storage`
   ```
   kubectl -n $NS edit pv $PV_NAME
   ```
   ```
    ...
    spec:
      accessModes:
      - ReadWriteOnce
      capacity:
        storage: 100Gi      ####  Resize PV storage
      claimRef:
        apiVersion: v1
        kind: PersistentVolumeClaim
   ```
5. Resize `PVC` storage.
   ```
   kubectl -n $NS edit pvc $RESOURCE_NAME 
   ```
   eg.: resize minio PVC to 128GB. <br>To resize minio pvc to 128GB, we need to update capacity storage under `status` section.
   ```
   $ kubectl -n minio edit pvc minio
    spec:
       accessModes:
       - ReadWriteOnce
       resources:
         requests:
           storage: 100Gi         ##### resize PVC storage
       storageClassName: longhorn
   ```
6. Check if the same is reflected on longhorn UI 
   ![resize-pvc-1.png](_images/resize-pvc-1.png)
7. Set `resource` replicas to one (1).
   ```
   kubectl -n $NS scale --replicas=1 $RESOURCE $RESOURCE_NAME
   ```
## Troubleshooting
In case the system is less on storage and pv gets into the resizing state due to less available storage then follow the below mentioned steps:
* Change the reclaim policy of the desired underlying  PV to Retain mode.
* Take the backup of the pvc yaml of the postgres.
* Delete the pvc.
* To ensure that the newly created PVC can bind to the PV marked Retain, manually edit the PV and delete the claimRef entry from the PV specs. This marks the PV as Available.
* Re-create the PVC in a smaller size, or a size that can be allocated by the underlying storage provider.
* Set the volumeName field of the PVC to the name of the PV. This binds the PVC to the provisioned PV only.
* Update the no of replicas for required PV to 2, this created one more volume on node5.
* Reduce the replica count of the required PV again back to 1.
* Remove the volumes copy which was there in previous existing node with less storage.
* Update the pvc of the postgres to higher allocatable size.
* Increase back the replication of the required resource attached to the pvc.
