# Monitoring (Metrics)

This directory holds the metrics-monitoring stacks for the cluster. Each
subdirectory is a self-contained stack with its own install scripts, Helm
values, and README. Pick **one** stack per cluster.

## Stacks

| Stack | Directory | Status | What it is |
|-------|-----------|--------|------------|
| **kube-prometheus-stack** | [`kube-prometheus-stack/`](./kube-prometheus-stack/) | ✅ Current | Upstream Prometheus + Alertmanager + node-exporter + kube-state-metrics. Independent of Rancher. Email alerting via Alertmanager. Metrics are visualised in the standalone Grafana deployed with the Loki logging stack. |
| **rancher-monitoring** | [`rancher-monitoring/`](./rancher-monitoring/) | ⚠️ Legacy | Rancher's packaged monitoring (prometheus-operator bundled with Rancher's Grafana). Retained for reference / older environments. |

## Which to choose

**Use `kube-prometheus-stack`** for all new and existing environments. It is the
current standard:

- Independent of Rancher (no `cattle-monitoring-system` dependency)
- Upstream chart — current Prometheus/Alertmanager versions, community dashboards
- Email alerting (Alertmanager) routed by severity, tagged per environment
- Metrics surface in the same standalone Grafana as logs (single pane of glass)

**Only use `rancher-monitoring`** if you are maintaining an older environment that
still runs it and cannot migrate yet. Do **not** deploy both on the same cluster —
two prometheus-operators fight over the shared CRDs and cause a pod-recreation loop.

## Migrating from rancher-monitoring → kube-prometheus-stack

If an environment currently runs rancher-monitoring, fully remove it first
(operator Deployment + Helm release, not just the CRD objects), then deploy
kube-prometheus-stack. See the
[kube-prometheus-stack PREREQUISITES](./kube-prometheus-stack/PREREQUISITES.md)
for the removal steps and the node/security-group prerequisites.

## Relationship to logging and alerting

- **Grafana** is deployed with the Loki stack under [`../logging/loki/`](../logging/loki/),
  not here. This stack sets `grafana.enabled: false` and only emits dashboard
  ConfigMaps for that Grafana to pick up.
- **Alerting** (Alertmanager) is part of kube-prometheus-stack — it is configured
  in that stack's values file, not a separate deployable.
- **Logs** are handled by the [`../logging/`](../logging/) stacks.