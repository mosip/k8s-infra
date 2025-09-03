# EBS storage classes
## Introduction
* EBS : Elastic block storage.
* EBS is the storage service provided by Amazon Web Services (AWS).
* EBS is primarily used within AWS environments, including Amazon Elastic Kubernetes Service (EKS).
## Different EBS storage classes
* General Purpose SSD
  * gp2:
    * Provides a balance of price and performance.
    * Suitable for a wide range of workloads, including development and test environments, as well as low-latency interactive applications.
    * By default EKS cluster gets created with gp2 as storage class generally. This can be checked by using below mentioned command:
      ```
      kubectl get sc
      ```
    * Output to verify storage class is gp2.
      ```
      NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
      gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   true               10d

      ```
    * In case gp2 is not present as storage class perform below mentioned steps.
      * Setup kubeconfig file correctly to use kubectl.
      * ```kubectl
        kubectl apply -f gp2-sc.yaml
        ```
    * Note in case need gp2 in retain mode use `gp2-sc-retain.yaml`.
  * gp3:
    * Newer generation of General Purpose SSDs, offering better performance and cost efficiency compared to gp2.
    * Allows to provision performance independent of storage capacity, offering up to 16,000 IOPS and 1,000 MiB/s throughput.
    * Steps to configure gp3 as storage class in EKS.
      * Setup kubeconfig file correctly to use kubectl.
      * ```kubectl
        kubectl apply gp3-sc.yaml
        ```
    * Check to verify storage class
      ```kubectl
      kubectl get sc
      ```
    * Output
      ```
      NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
      gp3             kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   true               10d

      ```
