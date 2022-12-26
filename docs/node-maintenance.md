# Remove unwanted docker images from cluster nodes to clear up space

* The cluster node contains unused images or containers which consumes node storage.

```
cd ../mosip/on-prem
```

* Create copy of `hosts.ini.sample` as `hosts.ini`. Update the IP addresses of your cluster nodes.

```
cd ../utils
```

* To remove unused containers, networks, images (both dangling and unused) and build cache on all the cluster nodes

```
ansible-playbook -i ../mosip/on-prem/hosts.ini remove-unwanted-docker-images.yaml
```
