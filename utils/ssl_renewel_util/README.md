# SSL Certificate Renewal Script for AWS

Note: If you are not using Route 53 from AWS as your DNS provider then this script won't work as-is. You'll have to manually renew the certificates, or — if you are using another DNS provider — check whether certbot supports a DNS plugin for it and update the certbot command inside the `renew_ssl_certs.sh` script accordingly; the script should then work fine.

This script renews SSL certificates using Let's Encrypt's `certbot`. It determines which certificate to renew from the certificate **nginx is actually serving** (read from the live nginx config), checks how close it is to expiry, and — if it is within the threshold — renews that exact certificate **in place** via certbot. certbot updates the `/etc/letsencrypt/live/` symlinks itself; the script does not move or rename any certificate directories.

> **Note on renewal method:** This script renews certificates **in place** using `certbot certonly --cert-name <lineage>`. It does **not** move the `live/` directory aside or rename cert directories by hand. Older manual runbooks that did `mv /etc/letsencrypt/live …` and then renamed a new `-00NN` directory are the cause of duplicate lineages and orphaned renewal configs — do not use that approach alongside this script.

## Prerequisites

- **Certbot**: Ensure `certbot` is installed and configured on your nginx server.
- **AWS Route 53**: The script uses Route 53 for DNS challenges.
- **Sudo Privileges**: Required to run certbot and reload services.
- **Nginx**: Ensure Nginx is installed and configured to use Let's Encrypt certificates (the script reads the served cert path from the nginx config).
- **SLACK_WEBHOOK_URL**: Create a new Slack webhook URL or use an existing one pointing to the desired Slack channel.

### Required IAM Permissions

The EC2 instance must have an IAM role with the following Route53 permissions so certbot can create and remove the DNS TXT challenge record automatically:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetChange",
        "route53:ChangeResourceRecordSets",
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "*"
    }
  ]
}
```

Verify access after installing AWS CLI in the VM:
```bash
aws route53 list-hosted-zones
```

## Installation

1. **Install Certbot**: Follow the instructions [here](https://certbot.eff.org/instructions) to install `certbot` for your nginx server.
2. **Configure AWS Route 53**: Ensure your domain's DNS is managed by AWS Route 53.
3. **Install AWS CLI**:
    ```sh
    sudo apt update
    sudo apt install unzip curl -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ```
4. **Verify AWS CLI Installation**:
    ```sh
    aws --version
    ```
5. **Grant Route53 access via the EC2 IAM role** (recommended). Attach a role with the permissions listed under *Required IAM Permissions* above to this instance. certbot and the AWS CLI will use the instance role automatically — no static access keys needed.

   > Avoid `sudo aws configure` with long-lived access keys. The instance IAM role is both sufficient and safer; static keys on the VM are an unnecessary credential to manage and rotate.
6. **Verify AWS Route53 Access**:
   ```sh
   sudo aws route53 list-hosted-zones
   ```
7. Your SSL certificates are assumed to be present under `/etc/letsencrypt/live/`, and nginx is configured to serve one of them via an `ssl_certificate` directive.
8. **Install the required packages**:
   ```sh
    sudo apt update
    sudo apt install certbot python3
    sudo apt-get install python3-certbot-dns-route53
    certbot plugins   # to list all the certbot plugins
   ```
9. **Script Permissions**: Make sure the script has execute permissions:
    ```sh
    chmod +x renew_ssl_certs.sh
    ```

## Usage

Run the script with the necessary permissions:

```sh
sudo ./renew_ssl_certs.sh
```

To automate renewal, a second script (`setup_ssl_cronjob.sh`) registers a cron job that runs `renew_ssl_certs.sh` daily; the renewal script itself only acts when the certificate is within 7 days of expiry, so no manual intervention is required.

# Schedule Certs Renew Cron Script

This script registers a cron job that runs `renew_ssl_certs.sh` daily at midnight. The renewal script renews only when the served certificate is within 7 days of expiry.

## Prerequisites

- `cron` installed and running
- Permissions to write to `/etc/cron.d/`
- nginx configured with an SSL certificate to serve

## How It Works

```
Every day at 00:00
       │
       ▼
Run prerequisite checks (6 checks)
       │
       ├── Any check fails? → Slack alert (red) → exit
       │
       ▼
Read the ssl_certificate path from the live nginx config (nginx -T)
Derive the lineage name from live/<name>/ and the domain from the cert SAN
       │
       ▼
Calculate days until expiry
       │
       ├── More than 7 days? → Log "no renewal needed" → exit cleanly
       │
       ▼
Send Slack alert (yellow) — "Renewal starting, X days left"
       │
       ▼
Run: certbot certonly --dns-route53 --cert-name <lineage> \
            --deploy-hook "systemctl reload nginx"
  - Creates DNS TXT record in Route53 automatically
  - Waits 30s for propagation
  - Let's Encrypt verifies domain ownership
  - Issues a new certificate
  - Updates symlinks in /etc/letsencrypt/live/ in place
  - Reloads nginx via the deploy-hook, ONLY if a cert was deployed
       │
       ├── certbot skipped (its own 30-day threshold)? → Slack alert (yellow) → exit
       ├── certbot failed? → Slack alert (red) with line number → exit
       │
       ▼
Verify new expiry is later than old expiry
       │
       ▼
Send Slack alert (green) — "Renewed successfully, new expiry: <date>"
```

> **Why read from nginx instead of scanning `live/`?** A host often has several certificate lineages under `/etc/letsencrypt/live/` (and duplicates such as `-0001`, `-0002`…). Picking one by scanning the directory can target the wrong cert. Reading the `ssl_certificate` path from the live nginx config guarantees the script checks and renews the certificate that is actually being served.

---

## Cron Schedule

Registered at `/etc/cron.d/ssl-cert-renewal`:

```
0 0 * * * root /usr/local/bin/renew_ssl_certs.sh >> /var/log/ssl_cert_renewal.log 2>&1
```

Runs daily at **midnight**. Safe to run daily — the script exits immediately if expiry is more than 7 days away, so there is no risk of hitting Let's Encrypt rate limits.

---

## Slack Notifications

| Colour | When | Message includes |
|---|---|---|
| 🟡 Yellow | Renewal starting | Domain, days until expiry, expiry date |
| 🟡 Yellow | Certbot skipped renewal | Domain, current expiry, days remaining |
| 🔴 Red | Prerequisite check failed | Hostname, log file path |
| 🔴 Red | Renewal failed | Domain, hostname, failed line number, exit code, log path |
| 🟢 Green | Renewal succeeded | Domain, old expiry, new expiry |

---

## Configuration

All configurable values are at the top of `renew_ssl_certs.sh`:

```bash
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."   # Slack incoming webhook URL
LOG_FILE="/var/log/ssl_cert_renewal.log"                   # Log file path
DAYS_THRESHOLD=7                                           # Renew if expiry is within this many days
```

> The certificate to renew is **not** configured here — it is derived at runtime from the certificate nginx is serving (via `nginx -T`), so the same script works unchanged across hosts that serve different domains.

---

## Logs

All output is written to `/var/log/ssl_cert_renewal.log`.

```bash
# Watch live during a manual run
tail -f /var/log/ssl_cert_renewal.log

# Check last run outcome
tail -50 /var/log/ssl_cert_renewal.log

# Check if cron fired
sudo grep "renew_ssl" /var/log/syslog | tail -20
```

Log entries are timestamped and prefixed with `INFO`, `WARN`, or `ERROR`:
```
[2026-06-10 00:00:01] INFO:  ========== Running prerequisite checks ==========
[2026-06-10 00:00:03] INFO:  CHECK 1/6: Sudo / root privileges...
[2026-06-10 00:00:03] INFO:    PASSED — running as root.
...
[2026-06-10 00:00:07] INFO:  nginx serves: /etc/letsencrypt/live/mosip.net/fullchain.pem
[2026-06-10 00:00:07] INFO:  Days until expiry  : 6
[2026-06-10 00:00:07] INFO:  Certificate expires in 6 days. Starting renewal...
```

## How to Deploy

### Step 1 — Copy scripts to the VM

```bash
scp renew_ssl_certs.sh setup_ssl_cronjob.sh ubuntu@<your-vm-ip>:~/
```

### Step 2 — Run the setup script

`setup_ssl_cronjob.sh` validates all prerequisites, copies `renew_ssl_certs.sh` into `/usr/local/bin/`, and registers the cron job. Run it once, from the directory containing both scripts.

```bash
sudo bash setup_ssl_cronjob.sh
```

Expected output if everything is in place:
```
INFO:  CHECK 1/6: Sudo / root privileges...       PASSED
INFO:  CHECK 2/6: certbot installation...         PASSED — certbot 2.x.x
INFO:  CHECK 3/6: certbot Route53 DNS plugin...   PASSED
INFO:  CHECK 4/6: AWS Route53 access...           PASSED — Hosted zones: N
INFO:  CHECK 5/6: nginx...                        PASSED
INFO:  CHECK 6/6: Locating and deploying renew_ssl_certs.sh... PASSED
INFO:  ========== All prerequisite checks PASSED ==========
```

### Step 3 — Run the renewal script manually to verify end-to-end

```bash
sudo /usr/local/bin/renew_ssl_certs.sh
```

Confirm from the log that it resolved the **correct** certificate — the `nginx serves:` and lineage lines should show the domain this host actually serves (e.g. `mosip.net`), not an unrelated lineage.

---

## Troubleshooting

* **No `ssl_certificate` found**: The script reads the served cert from `nginx -T`. If nginx has no `ssl_certificate` directive, or `nginx -t` fails, the prerequisite check aborts. Run `sudo nginx -t` and confirm an `ssl_certificate` line exists in the config.
* **Wrong certificate targeted**: Check the `nginx serves:` line in the log. The script renews whatever nginx points at; if that's wrong, fix the `ssl_certificate` path in the nginx config.
* **certbot `FileExistsError` / duplicate `-00NN` lineage**: Indicates a previously hand-modified `archive/`/`live/` directory. Resolve the lineage so `live/<name>/` is a proper certbot-managed symlink set before relying on automated renewal.
* **Permission issues**: Ensure the script runs as root (via `sudo`) so it can run certbot and reload nginx.
* Check the log file `/var/log/ssl_cert_renewal.log` for errors and script failures.