# Logging

This directory holds the log-collection + log-storage stacks for the cluster.
Each subdirectory is a self-contained stack with its own install scripts, Helm
values, and README. Pick **one** stack per cluster.

## Stacks

| Stack | Directory | Status | What it is |
|-------|-----------|--------|------------|
| **Loki** | [`loki/`](./loki/) | ✅ Current | Grafana Loki (log store) + Alloy (collector, DaemonSet) + the standalone Grafana that visualises both logs and metrics. Lightweight, label-based, cheaper at scale. |
| **rancher-logging** | [`rancher-logging/`](./rancher-logging/) | ⚠️ Legacy | Rancher's packaged logging (Fluentd / Fluent Bit via the Banzai Cloud logging-operator). Retained for reference / older environments. |

## Which to choose

**Use `loki`** for all new and existing environments. It is the current standard:

- Log collection via **Alloy** (DaemonSet) — unchanged coverage, runs on every node
- Logs stored in **Loki**, queried in **Grafana** with LogQL
- The **Grafana** here is the single pane of glass — it reads both Loki (logs) and
  Prometheus (metrics, from [`../monitoring/kube-prometheus-stack/`](../monitoring/kube-prometheus-stack/))
- Lighter weight and cheaper to run/retain than ELK

**Only use `rancher-logging`** if you are maintaining an older environment that
still runs it and cannot migrate yet. Do not run multiple logging backends on the
same cluster — they duplicate collection and compete for resources.

## What the move to Loki changes (and doesn't)

Replacing rancher-logging with Loki **does not** change log *coverage* — the same
pod logs are collected. What changes is the **backend** (Loki instead of
Elasticsearch/Fluentd), **where logs surface** (one standalone Grafana for both
logs and metrics), and the **collector** (Alloy).

## Relationship to monitoring and Grafana

- **Grafana lives here** (deployed with the Loki stack) and is shared: it reads
  logs from Loki *and* metrics from the Prometheus stack under
  [`../monitoring/kube-prometheus-stack`](../monitoring/kube-prometheus-stack). The Prometheus datasource is configured in
  this stack's `grafana-values.yaml`.
- **Metrics** are handled by the [`../monitoring/`](../monitoring/) stacks.