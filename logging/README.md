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

* Update propertes of Elasticsearch index in `ClusterOuputs` --> `Output Buffer` --> Edit YAML.
```
elasticsearch:
    buffer:
      flush_interval: 10s
      flush_mode: interval
    host: elasticsearch-master
    logstash_format: true
    port: 9200
    scheme: http
    ssl_verify: true
    ssl_version: TLSv1_2
flush_interval: 10s
flush_mode: interval
```
* Select `ClusterFlows` from `Logging` screen and create one with below mentioned configuration: 
    * Name: eg. elasticflow
    * Description: small description
    * select `Filters` and replace the contents with the contents of [filter.yaml](./filter.yaml)
    * select `Outputs` as the name of the `ClusterOutputs` and save the same.

TODO: Issues: Elasticsearch and Kibana pod logs are not getting recorded. Further, setting up Cluster Flow for pods specified by pod labels doesn't seem to work. Needs investigation.

## Indices
Daywise indices with the name `logstash*` are created once the above dashboards are imported. The `logstash_format: true` setting above enables the same.

## Filters
Note the filters applied in `filters.yaml`. You may update the same for your install if required. 

## Dashboards
* Open Kibana console `https://<hostname in kibana_values.yaml>//`
* Under Stack Management --> Saved Objects, import all dashboards under `dashbords/` folder in order of file names. 

## Traceid
You can click the `traceId` field to see the full log trace related to the particular `traceId`. The dashboard `02-error-only-logs.ndjson` contains field map for the same.  To setup such links manually, provide the following url in the given viewof Saved Objects --> logstash --> traceId 

![](../docs/_images/traceid-kibana-setting.png)
 
```
kibana#/discover/0efe9240-c521-11ec-92b4-4f5e54b3d2f7?_g=(filters:!(),refreshInterval:(pause:!t,value:10000),time:(from:now-15m,to:now))&_a=(columns:!(kubernetes.container_name,traceId,level,message),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,index:'1edfabd0-c3d8-11ec-a947-83cd2093795e',key:traceId.keyword,negate:!f,params:(query:'{{value}}'),type:phrase),query:(match_phrase:(traceId.keyword:'{{value}}')))),grid:(),hideChart:!f,index:'1edfabd0-c3d8-11ec-a947-83cd2093795e',interval:auto,query:(language:kuery,query:''),sort:!(!('@timestamp',desc)))
```

## Cleanup
To see day wise logs indices created in Elasticsearch login to one of the Master pods of Elasticsearch via Rancher and issue following command:
```
curl http://localhost:9200/_cat/indices | grep logstash
```
You may delete older logs.

## Troubleshooting
* If MOSIP logs are not seen, check if all fields here have quotes (except numbers):
Log pattern in [mosip-config](https://github.com/mosip/mosip-config/blob/develop3-v3/application-default.properties) property `server.tomcat.accesslog.pattern`.
* To check latest record in Elasticsearch index, login to ES shell (using Rancher or `kubectl exec`):
    ```sh
    curl -X POST -H 'Content-Type: application/json' -d '{ "query": { "match_all": {} }, "size": 1, "sort": [ { "@timestamp": { "order": "desc" } } ] }' http://localhost:9200/<index-name>/_search
    ```
