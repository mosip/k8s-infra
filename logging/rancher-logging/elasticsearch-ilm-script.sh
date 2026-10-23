#!/usr/bin/env bash

kubectl exec -it elasticsearch-master-0 -n cattle-logging-system -- curl -XPUT "http://elasticsearch-master:9200/_ilm/policy/3_days_delete_policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "delete": {
        "min_age": "3d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'
kubectl exec -it elasticsearch-master-0 -n cattle-logging-system -- curl -XPUT "http://elasticsearch-master:9200/_index_template/logstash_template" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["logstash-*"],
  "template": {
    "settings": {
      "index": {
        "lifecycle": {
          "name": "3_days_delete_policy"
        }
      }
    },
    "aliases": {},
    "mappings": {}
  }
}'
