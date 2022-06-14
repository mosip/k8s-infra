# Resize Existing PVC Storage

To resize existing PVC storage, follow the below procedure:

1. Set `resource` replicas to zero (0).
   ```
   kubectl -n resourceNameSpace scale --replicas=0 resourceObjectName resourceName
   ```
   eg.:
   ```
   kubectl -n minio scale --replicas=0 deploy minio
   ```
2. Resize `PVC` storage.
   ```
   kubectl -n resourceNameSpace edit pvc pvcName
   ```
   eg.: resize minio PVC to 128GB. <br>To resize minio pvc to 128GB, we need to update capacity storage under `status` section.
   ```
   $ kubectl -n minio edit pvc minio
    spec:
       accessModes:
       - ReadWriteOnce
       resources:
         requests:
           storage: 8Gi
       storageClassName: longhorn
       volumeMode: Filesystem
       volumeName: pvc-ccd5a77e-287d-41e2-af39-b63230a9a577
    status:
       accessModes:
       - ReadWriteOnce
       capacity:
         storage: 128Gi      ##### update the storage capacity
       phase: Bound
   ```
3. Check if the same is reflected on longhorn UI 
   ![resize-pvc-1.png](_images/resize-pvc-1.png)
4. Set `resource` replicas to one (1).
   ```
   kubectl -n resourceNameSpace scale --replicas=1 resourceObjectName resourceName
   ```
   eg.:
   ```
   kubectl -n minio scale --replicas=1 deploy minio
   ```