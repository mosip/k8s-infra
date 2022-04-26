# Logging

## Kibana
Kibana connects to Elasticsearch. Make sure you have a domain like `kibana.sandbox.xyz.net` pointing to your internal load balancer included in [global configmap](../mosip/global_configmap.yaml.sample).

## Install Elasticsearch, Kibana and Istio addons
```sh 
./install.sh
```

## Instal Rancher FluentD system
* Install `logging` from `Apps and marketplace` within the Rancher UI.

## Configure Rancher FluentD
To collect logs from MOSIP services create `ClusterOutputs` as belows:
* Select `Logging` from `Cluster Explorer`.
* Select `ClusterOutputs` from `Logging` screen and create one with below mentioned configuration:
    *  Name: eg. elasticsearch.
    *  Description: small description.
    *  select `Elasticsearch` as Output.
    *  update the `Target` as below and save the same.
      * _Output_: `Elasticsearch`, 
      * _Target_: `http`
      * _Host_: `elasticsearch-master` 
      * _Port_: `9200`.
* Select `ClusterFlows` from `Logging` screen and create one with below mentioned configuration: 
    * Name: eg. elasticflow
    * Description: small description
    * select `Filters` and replace the contents with the contents of [filter.yaml](./filter.yaml)
    * select `Outputs` as the name of the `ClusterOutputs` and save the same.

Note that with this filter any JSON object received in `log` field will be parsed into individual fields and indexed.

TODO: Issues: Elasticsearch and Kibana pod logs are not getting recorded. Further, setting up Cluster Flow for pods specified by pod labels doesn't seem to work. Needs investigation.

## View logs
* Open Kibana console `https://<hostname in kibana_values.yaml>//`
* In Kibana console add Index Pattern "fluentd*" under Stack Management.
* View logs in Home->Analytics->Discover.

## Troubleshooting
* If MOSIP logs are not seen, check if all fields here have quotes (except numbers):
Log pattern in [mosip-config](https://github.com/mosip/mosip-config/blob/develop3-v3/application-default.properties) property `server.tomcat.accesslog.pattern`.
* To check latest record in Elasticsearch index:
    ```
    curl -X POST -H 'Content-Type: application/json' -d '{ "query": { "match_all": {} }, "size": 1, "sort": [ { "@timestamp": { "order": "desc" } } ] }' http://localhost:9200/<index-name>/_search
    ```
