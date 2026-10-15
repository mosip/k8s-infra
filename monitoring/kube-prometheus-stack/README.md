# Standalone Monitoring + Alerting

Self-managed `kube-prometheus-stack` (Prometheus + Alertmanager + exporters)
for RKE2 clusters, with email alerting. Metrics are visualised in the existing
standalone Loki Grafana (metrics added there as a Prometheus datasource).

This stack is independent of Rancher-monitoring.

---

## Contents

| File | Purpose |
|------|---------|
| `deploy-monitoring.sh` | Deploys the stack (install/upgrade), creates the SMTP secret, verifies. |
| `values-monitoring.yaml` | Helm values — Prometheus, Alertmanager (email), control-plane scraping. |
| `PREREQUISITES.md` | Infra steps to do BEFORE deploying (security groups, cleanup). |
| `README.md` | This file. |

---

## Architecture

```
  ┌─────────────────────────── RKE2 cluster ─────────────────────────────┐
  │                                                                      │
  │  control-plane nodes          worker nodes                           │
  │  ├─ etcd metrics :2381         ├─ node-exporter :9100                │
  │  ├─ ctrl-mgr     :10257        └─ (workloads)                        │
  │  ├─ scheduler    :10259                                              │
  │  ├─ kube-proxy   :10249                                              │
  │  └─ node-exporter:9100                                               │
  │           │  (scraped over the node network — needs SG + bind-addr)  │
  │           ▼                                                          │
  │   ┌──────────────┐     fires alerts     ┌──────────────┐             │
  │   │  Prometheus  │ ───────────────────▶ │ Alertmanager │ ──▶ email   │
  │   │ (ns:monitoring)                     │ (severity routed)          │
  │   └──────┬───────┘                      └──────────────┘             │
  │          │ datasource                                                │
  │          ▼                                                           │
  │   ┌──────────────┐                                                   │
  │   │   Grafana    │  (standalone Loki stack — deploy-loki.sh)         │
  │   │ Loki + Prom  │                                                   │
  │   └──────────────┘                                                   │
  └──────────────────────────────────────────────────────────────────────┘
```

- **Prometheus** scrapes node-exporter (all nodes), kube-state-metrics,
  kubelet/cAdvisor, and the control-plane components.
- **Alertmanager** routes alerts by severity to email (critical / warning).
- **Grafana** is NOT deployed by this stack — the standalone Loki Grafana is the
  single pane of glass; Prometheus is added there as a datasource.

---

## Prerequisites

Read and complete **`PREREQUISITES.md`** before deploying. Summary:

1. **Remove rancher-monitoring fully** (operator Deployment + Helm release, not
   just CRD objects) if migrating from it. Leftovers cause a pod-recreate loop.
2. **Expose control-plane metrics** — add `bind-address` args to each
   control-plane node's `/etc/rancher/rke2/config.yaml`; restart with
   `stop → rke2-killall.sh → start` (NOT plain `systemctl restart`). Best baked
   into node provisioning so it's there on first boot.
3. **Open security-group ports** (Terraform-managed):
    - Worker SG: `9100`
    - Control-plane SG: `9100, 10257, 10259, 2381`
    - Source: the VPC CIDR (e.g. `172.31.0.0/16`), never `0.0.0.0/0`.
4. **SMTP credentials** ready for the email secret.

Tooling: `kubectl` + `helm` v3, cluster reachable, outbound access to GitHub
(for the CRD step) and the Helm chart repo.

---

## Deploy

```bash
# 1. edit the per-environment values (see "Per-environment values" below)
vi values-monitoring.yaml

# 2. run the deploy (prompts for the SMTP password, or set SMTP_PASSWORD env)
chmod +x deploy-monitoring.sh
./deploy-monitoring.sh
```

The script:
1. Pre-flight checks (kubectl/helm/cluster/values; warns if rancher-monitoring
   is still present).
2. Adds the Helm repo and verifies the pinned chart version.
3. Applies matching prometheus-operator CRDs server-side (prevents the
   stale-CRD schema loop).
4. Creates the `alertmanager-smtp` secret.
5. Installs/upgrades the stack.
6. Verifies pods and checks the Alertmanager StatefulSet isn't in a recreate
   loop.

---

## Per-environment values

When replicating to a new environment, edit the `# EDIT` markers in
`values-monitoring.yaml`. The main ones:

| Value | What | Example |
|-------|------|---------|
| `prometheus.prometheusSpec.externalLabels.cluster` | This env's name (shown in alerts) | `dev-int-inji` |
| `prometheus.prometheusSpec.externalLabels.tier` | For prod/non-prod routing | `nonprod` |
| `storageClassName` | Your cluster's StorageClass | `nfs-csi` |
| `alertmanager ... smtp_smarthost` | SMTP server | SES / Gmail / org relay |
| `alertmanager ... smtp_from` | Verified sender address | `alerts@...` |
| `alertmanager ... smtp_auth_username` | SMTP username | — |
| `email_configs ... to` | Recipients (critical / warning) | — |

And in the deploy script:

| Variable | What |
|----------|------|
| `KPS_CHART_VERSION` | kube-prometheus-stack chart version (pin to the one you validated — `helm list -n monitoring` shows the current CHART) |
| `PROM_OPERATOR_CRD_VERSION` | prometheus-operator version matching the chart's operator |

The `externalLabels` block is the ONE thing that genuinely differs per
environment. The Alertmanager routing is otherwise identical across envs — it
routes on `tier` and displays `cluster`.

---

## Alerting

Alerts route by the `severity` label:

| Severity | Destination |
|----------|-------------|
| `critical` | critical recipient (email) |
| `warning` | warning recipient (email) |
| `Watchdog`, `InfoInhibitor` | dropped (null) |

Every alert's subject is prefixed with the environment, e.g.
`[dev-int-inji] [FIRING] KubeNodeNotReady`.

**Email requires an SMTP server** — Alertmanager cannot send mail on its own.
The password is mounted from the `alertmanager-smtp` secret (not in the values
file). For AWS SES, verify the sender and ensure the account is out of sandbox
mode.

### Test email end-to-end

```bash
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093
curl -XPOST http://localhost:9093/api/v2/alerts -H "Content-Type: application/json" -d '[{
  "labels": {"alertname":"EmailTest","severity":"critical","cluster":"dev-int-inji"},
  "annotations": {"summary":"Test","description":"Verifying email delivery"}
}]'
# → check the configured inbox
```

---

## Post-deploy: wire Prometheus into the Loki Grafana

This stack does not deploy Grafana. Add Prometheus as a datasource in the
standalone Loki Grafana (the `grafana/grafana` release in `deploy-loki.sh`):

```yaml
# in the Loki Grafana's values datasources block, alongside Loki:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
  jsonData:
    timeInterval: 1m
```

Then `helm upgrade` that Grafana release. Set the dashboard sidecar's
`searchNamespace: ALL` so it also picks up the kube-prometheus-stack dashboards
emitted in the `monitoring` namespace.

---

## Verify

```bash
# pods healthy
kubectl get pods -n monitoring

# all targets UP (node-exporter on every node, control-plane components)
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
#   → http://localhost:9090/targets

# how many node-exporters report (should equal node count)
#   query in Prometheus:  count(up{job="node-exporter"} == 1)
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Only some nodes report node-exporter; DOWN targets show `context deadline exceeded` | SG missing port `9100` on the worker/control-plane SG | Add the ingress rule (PREREQUISITES step 3). ICMP/ping working does not mean the port is open. |
| etcd/scheduler/controller-manager targets DOWN | node `config.yaml` bind-address not applied, or SG missing `10257/10259/2381` | Prereqs 2 & 3. |
| Alertmanager pod recreating in a loop; StatefulSet `generation` climbing fast | Leftover rancher-monitoring operator fighting this one, OR stale CRDs (`.status.selector: field not declared`) | Remove rancher-monitoring operator + helm release (prereq 1); ensure CRDs upgraded (deploy step 3). |
| `rke2-server` fails on restart: `bind: address already in use` on `:2381` | Plain `systemctl restart` left old etcd holding the port | `systemctl stop` → `rke2-killall.sh` → `systemctl start`. Baking the config into provisioning avoids this entirely. |
| etcd pod `0/1`, readiness probe failing after metrics change | `listen-metrics-urls` dropped the localhost endpoint | Use `http://0.0.0.0:2381` (includes localhost), not a pinned node IP alone. |
| Email not delivered, config looks right | SMTP auth/sender/TLS, or SES sandbox mode | Check `kubectl -n monitoring logs <alertmanager-pod> -c alertmanager`. For SES: verify sender + request production access. |
| Prometheus only scrapes targets on its own node | Prometheus scheduled on a node with broken outbound networking | Reachability is per Prometheus's node — confirm its node can reach peers; the usual root cause is the SG `9100` gap above. |

---

## Notes

- **Security groups are Terraform-managed.** Any manual SG rule is wiped on the
  next `terraform apply`. Put the ingress rules in the Terraform SG definitions
  so every rebuilt cluster has them.
- **Node config is best set at provisioning time** (cloud-init / Terraform /
  Ansible), so new nodes expose metrics on first boot with no restart dance.
- **CRD lifecycle:** Helm installs CRDs on first install but does NOT upgrade
  them on `helm upgrade`. The server-side CRD apply in the deploy script handles
  both fresh installs with stale CRDs present and chart-version bumps.