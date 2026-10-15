# Monitoring + Alerting — Prerequisites

These steps must be completed **before** running `deploy-monitoring.sh`.
They are infrastructure-level changes (node OS config and AWS security
groups) that live outside Helm and are not automated by the deploy script.

---

## 1. Fully remove rancher-monitoring (if present)

**This is the most important prerequisite.** A leftover rancher-monitoring
operator causes a fatal "two operators fighting" loop that endlessly recreates
the Alertmanager/Prometheus pods (observed: StatefulSet generation climbing into
the tens of thousands, pod recreating every ~3s).

Removing only the CRD *objects* is not enough — the operator **Deployment** and
Helm release must go too.

```bash
# check what rancher-monitoring leftovers exist:
kubectl get pods -n cattle-monitoring-system | grep -i operator
helm list -n cattle-monitoring-system

# remove the Helm release (covers operator + workloads):
helm uninstall rancher-monitoring -n cattle-monitoring-system

# once the namespace is drained:
kubectl delete namespace cattle-monitoring-system
```

Do NOT delete the prometheus-operator CRDs here — the new stack reuses the same
CRD *kinds* (the deploy script upgrades their schema). See step 4.

---

## 2. Expose control-plane component metrics (control-plane nodes only)

The control-plane components (controller-manager, scheduler, kube-proxy, etcd)
bind their metrics to localhost by default on RKE2. Expose them so Prometheus
can scrape them cross-node.

On **each control-plane node**, edit `/etc/rancher/rke2/config.yaml` and add:

```yaml
kube-controller-manager-arg:
  - bind-address=0.0.0.0
kube-scheduler-arg:
  - bind-address=0.0.0.0
kube-proxy-arg:
  - metrics-bind-address=0.0.0.0
etcd-arg:
  - listen-metrics-urls=http://0.0.0.0:2381
```

Then restart RKE2 — **use stop → killall → start, NOT `systemctl restart`**.
A plain restart leaves the old etcd holding port 2381, causing
`bind: address already in use` on the temporary-etcd reconcile.

```bash
sudo systemctl stop rke2-server
sudo /usr/local/bin/rke2-killall.sh
sudo systemctl start rke2-server
```

**Do ONE control-plane node at a time.** Wait for the node to be Ready and etcd
quorum healthy before touching the next:

```bash
kubectl get nodes
kubectl -n kube-system get pods | grep etcd   # all etcd members 1/1
kubectl get --raw='/readyz?verbose'
```

Take an etcd snapshot first as a rollback point:
```bash
sudo rke2 etcd-snapshot save --name pre-metrics-change
```

Workers do NOT get these args (the components don't run there), except optionally
`kube-proxy metrics-bind-address` if you want kube-proxy metrics from workers.

---

## 3. AWS Security Group ingress rules (Terraform-managed)

Node-exporter and the control-plane component metrics ports must be reachable
between nodes. The node security groups are **Terraform-managed**, so add these
rules to the Terraform SG definitions (a manual console/CLI add will be wiped on
the next `terraform apply`).

Source CIDR for all rules: the VPC/node CIDR (e.g. `172.0.0.0/8` or, better,
your actual VPC CIDR like `172.31.0.0/16`).

**Worker node SG** — add:
| Port | Purpose |
|------|---------|
| 9100 | node-exporter |

**Control-plane node SG** — ensure present:
| Port  | Purpose |
|-------|---------|
| 9100  | node-exporter |
| 10257 | kube-controller-manager |
| 10259 | kube-scheduler |
| 2381  | etcd metrics |

Verify reachability after applying (from any node):
```bash
curl -m 3 http://<other-node-ip>:9100/metrics  -o /dev/null -w "%{http_code}\n"   # 200
curl -m 3 -k https://<cp-node-ip>:10257/metrics -o /dev/null -w "%{http_code}\n"   # 403 = up + authed
```

> Note: a missing 9100 ingress rule on the worker SG is the classic cause of
> "only some nodes report in Prometheus" — node-exporter is up on every node but
> unreachable. ICMP (ping) working does NOT mean the metrics port is open.

---

## 4. CRD schema (handled by the deploy script, noted here for awareness)

`kube-prometheus-stack` installs CRDs only if absent; it will NOT upgrade CRDs
left over from a previous prometheus-operator (e.g. an old rancher-monitoring).
Stale CRDs cause `.status.selector`/`.status.shards: field not declared in
schema` errors and a reconcile loop.

`deploy-monitoring.sh` applies the matching CRDs with `--server-side` before the
Helm install to prevent this. No manual action needed — documented so you know
why that step exists.

---

## 5. SMTP credentials for email alerting

Alertmanager relays email through an SMTP server. Have ready:
- SMTP smarthost + port (e.g. SES `email-smtp.ap-south-1.amazonaws.com:587`)
- A verified sender address
- SMTP username + password

The deploy script creates the `alertmanager-smtp` Kubernetes secret from these.

For AWS SES specifically: the sender/domain must be **verified**, and if the SES
account is in **sandbox mode** it can only send to verified recipients — request
production access for sending to arbitrary inboxes.

Note: Make sure to update the verified sender address in the `values-monitoring.yaml` file before installing. 