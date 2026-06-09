# Loki Monitoring Stack — Deployment Guide

> **Environment:** RKE2 v1.28.9 | 11 Nodes | Monolithic Mode

---

## Table of Contents

- [What is This Stack?](#what-is-this-stack)
- [How the Components Work Together](#how-the-components-work-together)
- [Component Overview](#component-overview)
    - [Loki](#loki)
    - [Grafana Alloy](#grafana-alloy)
    - [Grafana](#grafana)
- [Repository Structure](#repository-structure)
- [Configuration Files](#configuration-files)
- [Deployment](#deployment)
- [Deletion / Uninstall](#deletion--uninstall)
- [Accessing Grafana](#accessing-grafana)
- [Useful LogQL Queries](#useful-logql-queries)
- [Troubleshooting](#troubleshooting)

---

## What is This Stack?

This stack gives you **centralized log aggregation and visualization** for all workloads running across kubernetes cluster.

In simple terms:

```
Your Pods → Alloy (collects logs) → Loki (stores logs) → Grafana (view & query logs)
```

Without this stack, logs live only inside individual pods and are lost when a pod restarts. With this stack, all logs are collected in real time, stored centrally, and searchable through a web UI.

---

## How the Components Work Together

```
┌─────────────────────────────────────────────────────────────┐
│                     RKE2 Cluster                            │
│                                                             │
│  ┌──────────┐    logs     ┌───────────┐   store   ┌──────┐ │
│  │  Your    │ ──────────► │   Alloy   │ ────────► │ Loki │ │
│  │  Pods    │             │ (DaemonSet│           │      │ │
│  └──────────┘             │  1/node)  │           └──┬───┘ │
│                           └───────────┘              │     │
│                                                      │query│
│                                               ┌──────▼───┐ │
│                                               │ Grafana  │ │
│                                               │(Web UI)  │ │
│                                               └──────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Flow:**
1. **Alloy** runs as a DaemonSet — one pod per node — and continuously tails container log files from the node's filesystem.
2. Alloy processes, filters, and labels logs, then pushes them to **Loki**.
3. **Loki** stores logs indexed by labels (namespace, pod, container, level, etc.) — it does NOT index the full log text, which keeps it lightweight.
4. **Grafana** connects to Loki as a data source. You use the Explore tab to query logs using LogQL (Loki's query language).

---

## Component Overview

### Loki

**What it is:** A log aggregation system built by Grafana Labs. Often described as *"Prometheus, but for logs."*

**Key concepts:**
- Stores logs as compressed chunks on disk (or object storage).
- Indexes only **labels** (e.g., `namespace`, `pod`, `level`) — not the full log content. This makes it much cheaper than Elasticsearch.
- Deployed here in **monolithic mode** — a single pod handles all functions. Suitable for clusters with moderate log volume.
- Exposes an HTTP API on port `3100`.

**Why monolithic mode?** For 11 nodes and 15–20 microservices, monolithic mode is simpler to operate and resource-efficient. Distributed/microservice mode would only be needed at much higher scale.

---

### Grafana Alloy

**What it is:** Grafana's next-generation observability collector (successor to Promtail and Grafana Agent). Runs as a **DaemonSet** so every node has exactly one Alloy pod collecting logs from pods scheduled on that node.

**What it does in this setup:**
- Discovers pods running on its own node via the Kubernetes API.
- Reads log files from `/var/log/pods/` on the node.
- **Drops noise early** — health checks, actuator endpoints, `/metrics` scrapes are discarded before any processing.
- **Parses JSON logs** and extracts fields like `level`, `statusCode`, `timeTaken`, `appName`.
- **Samples logs** — DEBUG dropped entirely, INFO kept at 30%, ACCESS logs kept at 10% (metrics cover the rest), WARN/ERROR kept at 100%.
- Attaches labels: `namespace`, `pod`, `container`, `host`, `app`, `level`, `cluster`, `environment`.
- Pushes processed logs to Loki.
- Also exports its own Prometheus metrics to your existing monitoring system.

**Why sampling?** High-volume INFO and ACCESS logs are repetitive. Sampling reduces storage and cost while keeping all meaningful signals (errors and warnings are never sampled).

---

### Grafana

**What it is:** The web-based visualization and dashboarding platform. In this stack it serves as the **frontend** for querying Loki logs.

**What you can do:**
- Use the **Explore** tab to write LogQL queries and view logs in real time.
- Build **dashboards** that show log volume, error rates, and service health.
- Set up **alerts** based on log patterns (e.g., alert when error rate exceeds a threshold).
- Grafana is pre-configured with Loki as a data source via `grafana-values.yaml`.

---

## Repository Structure

```
logging/loki/
├── deploy-loki.sh              # Main deployment script
├── delete.sh              # Uninstall / cleanup script
│
├── loki-values.yaml            # Helm values for Loki
├── grafana-values.yaml         # Helm values for Grafana
├── alloy-values.yaml           # Helm values for Grafana Alloy (includes config)
│
├── istio-addons-values.yaml    # Helm values for Istio-addons
└── README.md      # README file for loki setup
```

---

## Configuration Files

### `loki-values.yaml`
Helm values for the Loki deployment. Key settings to be aware of:
- **Deployment mode** — set to `monolithic` for this environment.
- **Storage** — configures PersistentVolumeClaims for log chunk storage.
- **Retention** — how long logs are kept before being deleted.
- **Resource limits** — CPU and memory requests/limits for the Loki pod.

### `grafana-values.yaml`
Helm values for Grafana. Key settings:
- **Datasource** — pre-configures Loki as a datasource pointing to `http://loki.loki-monitoring.svc.cluster.local:3100`.
- **Service type** — controls how Grafana is exposed (ClusterIP, NodePort, or LoadBalancer).
- **Persistence** — enables a PVC so dashboards survive pod restarts.
- **Admin password** — set via `--set adminPassword` in the deploy script (do not store plaintext in the values file).

### `alloy-values.yaml`
Helm values for Grafana Alloy. The most important section is `alloy.configMap.content`, which contains the full **Alloy River config** — the pipeline that defines how logs are collected, processed, and shipped. Key pipeline stages:

| Stage | Purpose |
|---|---|
| `discovery.kubernetes` | Finds pods on the local node |
| `discovery.relabel` | Filters out system namespaces, maps labels |
| `loki.source.kubernetes` | Reads actual log streams from pods |
| `loki.process "drop_noise"` | Drops health checks and old logs early |
| `loki.process "access_to_metrics"` | Converts ACCESS logs to Prometheus histograms |
| `loki.process "main_logs"` | Parses JSON, samples by level, adds labels |
| `loki.write` | Pushes processed logs to Loki |
| `prometheus.remote_write` | Ships Alloy's own metrics to Prometheus |


---

## Deployment

### Pre-requisites

- `kubectl` installed and configured, connected to your RKE2 cluster.
- `helm` v3 installed.
- All YAML files present in the same directory as `deploy-loki.sh`.

### Steps

```bash
# 1. Clone or copy the deployment files to your working directory

# 2. Review and update configuration
#    - Review alloy-values.yaml and update cluster/environment labels if needed
#    - Review grafana-values.yaml and update the values as per the requirement.
#    - Review loki-values.yaml and update the values as per the requirement.

# 3. Make the script executable
chmod +x deploy-loki.sh

# 4. Run the deployment script
./deploy-loki.sh
```

### What the Script Does (Step by Step)

| Step | Action |
|---|---|
| Pre-flight | Checks kubectl, helm, cluster connectivity, and required files |
| Step 1 | Creates the `loki-monitoring` namespace |
| Step 2 | Adds the Grafana Helm repo and updates |
| Step 3 | Installs or upgrades **Loki** |
| Step 4 | Installs or upgrades **Grafana** |
| Step 5 | Installs or upgrades **Grafana Alloy** |
| Step 6 | Prints pod and service status |
| Step 7 | Prints access instructions |
| Step 8 | Waits for Loki and Grafana pods to reach Ready state |

> The script is **idempotent** — running it again will upgrade existing releases rather than failing.

---

## Deletion / Uninstall

```bash
chmod +x delete.sh
./delete.sh
```

The delete script will prompt you to type `yes` before making any changes.

**What gets removed:**
- Helm releases: `alloy`, `grafana`, `loki`
- All PersistentVolumeClaims (log data will be permanently lost)
- Leftover ConfigMaps
- The `loki-monitoring` namespace

> ⚠️ **This is irreversible.** All stored logs and Grafana dashboards will be deleted.

**Uninstall order** mirrors reverse of install: Alloy is removed first (stops log shipping), then Grafana, then Loki (storage backend removed last).

---

## Accessing Grafana

### Port-Forward (Quick Access)

```bash
kubectl port-forward -n loki-monitoring svc/grafana 3000:80
```

Then open: **http://localhost:3000**

```
Username: admin
Password: <value of GRAFANA_PASSWORD in deploy-loki.sh>
```

> This only works while the port-forward command is running in your terminal. For persistent access, use NodePort or LoadBalancer (see `grafana-values.yaml`).

### Loki API Health Check

```bash
kubectl port-forward -n loki-monitoring svc/loki 3100:3100
curl http://localhost:3100/ready
```

Should return: `ready`

---

## Useful LogQL Queries

Use these in **Grafana → Explore** with the Loki datasource selected.

```logql
# All logs from the cluster
{cluster="rke2"}

# Logs from a specific namespace
{namespace="mosip"}

# Filter for errors only
{cluster="rke2"} |= "error"

# Errors from a specific app
{app="registration-processor"} | json | level =~ "(?i)error"

# HTTP 5xx errors
{cluster="rke2"} | json | statusCode =~ "5.."

# Logs from a specific pod
{pod="my-pod-name-abc123"}

# Count error logs per minute (for dashboards)
sum(rate({cluster="rke2"} | json | level="ERROR" [1m])) by (namespace)
```

---

## Troubleshooting

**Pods not starting:**
```bash
kubectl get pods -n loki-monitoring
kubectl describe pod <pod-name> -n loki-monitoring
kubectl logs <pod-name> -n loki-monitoring
```

**No logs appearing in Grafana:**
```bash
# Check Alloy is running on all nodes
kubectl get pods -n loki-monitoring -l app.kubernetes.io/name=alloy -o wide

# Check Alloy logs for errors
kubectl logs -n loki-monitoring -l app.kubernetes.io/name=alloy --tail=50

# Verify Loki is receiving data
kubectl port-forward -n loki-monitoring svc/loki 3100:3100
curl "http://localhost:3100/loki/api/v1/labels"
```

**Loki PVC pending:**
```bash
kubectl get pvc -n loki-monitoring
# If Pending, check your StorageClass is available
kubectl get storageclass
```

**Grafana cannot reach Loki:**
- Verify the datasource URL in Grafana Settings → Data Sources → Loki.
- Should be: `http://loki.loki-monitoring.svc.cluster.local:3100`
- Test the connection using the **Save & Test** button in Grafana.
