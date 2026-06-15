# SSL Certificate Renewal Script for Aws
Note: If you are not using Route 53 from Aws as your Dns provider then this script won't work. You'll have to manually renew the certificates, In case if you are using any other Dns provider then check if certbot supports any dns plugin for your Dns provider and then just update the certbot command within the script then the `renew_ssl_certs` script should work fine.

This script is used for the renew of SSL certificates using Let's Encrypt's `certbot`. It moves old certificates to a backup directory with an expiry date and renew the ssl certificates and Update cert directory name.

## Prerequisites

- **Certbot**: Ensure `certbot` is installed and configured on your nginx server.
- **AWS Route 53**: The script uses Route 53 for DNS challenges.
- **Sudo Privileges**: Required to move directories and restart services.
- **Nginx**: Ensure Nginx is installed and configured to use Let's Encrypt certificates.
- **SLACK_WEBHOOK_URL**: Create a new slack webhook url or Use an existing slack webhook url pointing to the specified slack channel.

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

Verify access after installing AWS CLI in the vm:
```bash
aws route53 list-hosted-zones
```

## Installation

1. **Install Certbot**: Follow the instructions [here](https://certbot.eff.org/instructions) to install `certbot` for your nginx server.
2. **Configure AWS Route 53**: Ensure your domain's DNS is managed by AWS Route 53 and that you have the necessary permissions to perform DNS validation.
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
5. **Configure AWS CLI (Using Root User)**
    ```sh
   sudo aws configure
    ```
   Configure your aws account using the above command by providing `Access_key_id` and `Secret_access_key`. Make sure you have right access to Route 53 service so that dns records can be added and verfified by let's-encrypt while renewing the ssl certs.
6. **Verify AWS Route53 Access**: Verify access after installing AWS CLI and configuring in the vm:
   ```
   sudo aws route53 list-hosted-zones
   ```
7. Your private and public ssl certificates are assumed to be present in the location "/etc/letsencrypt/live/".
8. **Install the required Packages**:
   ```sh
    sudo apt update
    sudo apt install certbot python3
    sudo apt-get install python3-certbot-dns-route53
    certbot plugins #To list all the certbot plugins
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

In Order to Automate the renewal of SSL certificates we have created another script which exicutes the `renew_ssl_certs` script on 7 days before the date of expiry using a cron without any manual intervention.

# Schedule Certs Renew Cron Script

This script schedules a cron job to run a specified script (`renew_ssl_certs.sh`) at 12am on 7 days before the expiry date.

## Prerequisites

- `cron` installed and running
- Permissions to edit cron jobs for the current user
- domain name of the environment

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
Read certificate from /etc/letsencrypt/live/
Extract domain from SAN field
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
Run: certbot certonly --dns-route53 --cert-name <domain>
  - Creates DNS TXT record in Route53 automatically
  - Waits 30s for propagation
  - Let's Encrypt verifies domain ownership
  - Issues new certificate
  - Updates symlinks in /etc/letsencrypt/live/ in place
       │
       ├── certbot skipped (its own 30-day threshold)? → Slack alert (yellow) → exit
       ├── certbot failed? → Slack alert (red) with line number → exit
       │
       ▼
Verify new expiry is later than old expiry
       │
       ▼
Reload nginx gracefully (systemctl reload — no dropped connections)
       │
       ▼
Send Slack alert (green) — "Renewed successfully, new expiry: <date>"
```
 
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
| 🟡 Yellow | Prerequisite check started | Hostname |
| 🟡 Yellow | Renewal starting | Domain, days until expiry, expiry date |
| 🟡 Yellow | Certbot skipped renewal | Domain, current expiry, days remaining |
| 🔴 Red | Prerequisite check failed | Hostname, log file path |
| 🔴 Red | Renewal failed | Domain, hostname, failed line number, exit code, log path |
| 🟢 Green | Renewal succeeded | Domain, old expiry, new expiry |
 
---

---

## Configuration

All configurable values are at the top of `renew_ssl_certs.sh`:

```bash
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."   # Slack incoming webhook URL
CERT_DIR="/etc/letsencrypt/live"                           # Path to letsencrypt live directory
LOG_FILE="/var/log/ssl_cert_renewal.log"                   # Log file path
DAYS_THRESHOLD=7                                           # Renew if expiry is within this many days
```
 
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
[2026-06-10 00:00:07] INFO:  Days until expiry  : 6
[2026-06-10 00:00:07] INFO:  Certificate expires in 6 days. Starting renewal...
```


## How to Deploy

### Step 1 — Copy scripts to the VM

```bash
scp renew_ssl_certs.sh setup_ssl_cronjob.sh ubuntu@<your-vm-ip>:~/
```

### Step 2 — Copy the renewal script to the system path

```bash
sudo cp renew_ssl_certs.sh /usr/local/bin/renew_ssl_certs.sh
sudo chmod +x /usr/local/bin/renew_ssl_certs.sh
```

### Step 3 — Run the setup script

This validates all prerequisites and registers the cron job. Run it once.

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
INFO:  CHECK 6/6: Renewal script at /usr/local/bin/renew_ssl_certs.sh... PASSED
INFO:  ========== All prerequisite checks PASSED ==========
```

### Step 4 — Run the renewal script manually to verify end-to-end

```bash
sudo /usr/local/bin/renew_ssl_certs.sh
```
 
---

## Troubleshooting

* No Crontab for User: If you see no crontab for <user>, it means there are no existing cron jobs for the user. The script will still create the new cron job.
* Invalid Date Format: Ensure you enter the date in YYYY-MM-DD format.
* Permission Issues: Ensure you have the necessary permissions to edit cron jobs for the current user.
* check the log file "ssl_cert_renewal.log" for errors and script failures.
