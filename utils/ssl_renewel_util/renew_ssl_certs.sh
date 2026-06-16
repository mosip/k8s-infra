#!/bin/bash
# =============================================================================
# renew_ssl_certs.sh
# Checks SSL certificate expiry and renews if within 7 days.
# Sends Slack notifications on success or failure.
# =============================================================================

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------
SLACK_WEBHOOK_URL="<slack_webhook_url>"
CERT_DIR="/etc/letsencrypt/live"
LOG_FILE="/var/log/ssl_cert_renewal.log"
DAYS_THRESHOLD=7
RENEWAL_SUCCESS=false
MOSIP_DOMAIN="unknown"

# --------------------------------------------------------------------------
# Logging — all stdout and stderr go to log file and console
# --------------------------------------------------------------------------
exec > >(tee -a "$LOG_FILE") 2>&1

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
info() { log "INFO:  $1"; }
warn() { log "WARN:  $1"; }
err()  { log "ERROR: $1"; }

# --------------------------------------------------------------------------
# Slack notification helper
# $1 = message text
# $2 = "good" (green), "warning" (yellow), or "danger" (red)
# --------------------------------------------------------------------------
send_slack_notification() {
  local message="$1"
  local color="${2:-good}"

  curl -s -X POST -H 'Content-type: application/json' \
    --data "{
      \"attachments\": [
        {
          \"color\": \"${color}\",
          \"text\": \"${message}\",
          \"footer\": \"SSL Renewal Bot | $(hostname) | $(date '+%Y-%m-%d %H:%M:%S')\"
        }
      ]
    }" \
    "$SLACK_WEBHOOK_URL"
}

# --------------------------------------------------------------------------
# ERR trap — fires if any command exits with non-zero
# --------------------------------------------------------------------------
trap_error() {
  local exit_code=$?
  local line_number=$1
  err "Script failed at line ${line_number} with exit code ${exit_code}."
  if [ "$RENEWAL_SUCCESS" = false ]; then
    send_slack_notification \
      ":x: *SSL Renewal FAILED* for \`${MOSIP_DOMAIN}\` on \`$(hostname)\`.\nScript exited at line ${line_number} (exit code: ${exit_code}).\nCheck logs: \`${LOG_FILE}\`" \
      "danger"
  fi
  exit "$exit_code"
}
trap 'trap_error $LINENO' ERR
trap 'exit 0' TERM

# --------------------------------------------------------------------------
# Strict mode — set AFTER trap so the trap catches errors
# --------------------------------------------------------------------------
set -euo pipefail

# ==========================================================================
# PREREQUISITE CHECKS
# All checks run before any renewal logic.
# Script exits with a clear message if any prerequisite fails.
# ==========================================================================
info "========== Running prerequisite checks =========="
PREREQ_FAILED=false

# --------------------------------------------------------------------------
# Check 1: Script must run as root (required for certbot, nginx, letsencrypt)
# --------------------------------------------------------------------------
info "CHECK 1/6: Sudo / root privileges..."
if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root or with sudo."
  err "Run: sudo $0"
  PREREQ_FAILED=true
else
  info "  PASSED — running as root."
fi

# --------------------------------------------------------------------------
# Check 2: certbot is installed
# --------------------------------------------------------------------------
info "CHECK 2/6: certbot installation..."
if ! command -v certbot &>/dev/null; then
  err "certbot is not installed or not in PATH."
  err "Install it with: sudo apt install certbot python3-certbot-dns-route53"
  PREREQ_FAILED=true
else
  CERTBOT_VERSION=$(certbot --version 2>&1)
  info "  PASSED — ${CERTBOT_VERSION}"
fi

# --------------------------------------------------------------------------
# Check 3: certbot Route53 DNS plugin is installed
# --------------------------------------------------------------------------
info "CHECK 3/6: certbot Route53 DNS plugin..."
if ! python3 -c "import certbot_dns_route53" &>/dev/null; then
  err "certbot Route53 DNS plugin is not installed."
  err "Install it with: sudo apt install python3-certbot-dns-route53"
  err "Or via pip:      sudo pip install certbot-dns-route53"
  PREREQ_FAILED=true
else
  info "  PASSED — certbot-dns-route53 plugin is available."
fi

# --------------------------------------------------------------------------
# Check 4: AWS credentials / IAM role — can the instance talk to Route53?
# --------------------------------------------------------------------------
info "CHECK 4/6: AWS Route53 access (IAM role or credentials)..."
if ! command -v aws &>/dev/null; then
  warn "  aws CLI not found — skipping Route53 IAM check."
  warn "  Install with: sudo apt install awscli"
  warn "  Certbot will still attempt Route53 access using instance metadata."
else
  if aws route53 list-hosted-zones --output text &>/dev/null; then
    ZONE_COUNT=$(aws route53 list-hosted-zones --query 'length(HostedZones)' --output text 2>/dev/null || echo "unknown")
    info "  PASSED — Route53 accessible. Hosted zones found: ${ZONE_COUNT}"
  else
    err "  AWS CLI cannot access Route53."
    err "  Ensure this EC2 instance has an IAM role with these permissions:"
    err "    route53:GetChange"
    err "    route53:ChangeResourceRecordSets"
    err "    route53:ListHostedZones"
    err "    route53:ListResourceRecordSets"
    PREREQ_FAILED=true
  fi
fi

# --------------------------------------------------------------------------
# Check 5: nginx is installed and its config is valid
# --------------------------------------------------------------------------
info "CHECK 5/6: nginx installation and configuration..."
if ! command -v nginx &>/dev/null; then
  err "nginx is not installed or not in PATH."
  err "Install it with: sudo apt install nginx"
  PREREQ_FAILED=true
else
  NGINX_VERSION=$(nginx -v 2>&1)
  info "  PASSED — ${NGINX_VERSION}"

  # Validate nginx config
  if ! sudo nginx -t &>/dev/null; then
    err "nginx configuration test failed. Run 'sudo nginx -t' for details."
    PREREQ_FAILED=true
  else
    info "  PASSED — nginx config syntax is valid."
  fi
fi

# --------------------------------------------------------------------------
# Check 6: letsencrypt live directory and cert exist
# --------------------------------------------------------------------------
info "CHECK 6/6: Let's Encrypt certificate directory..."
if [ ! -d "$CERT_DIR" ]; then
  err "Certificate directory ${CERT_DIR} does not exist."
  err "Ensure certbot has been run at least once to issue an initial certificate."
  PREREQ_FAILED=true
else
  FULLCHAIN_COUNT=$(find "$CERT_DIR" -maxdepth 2 -name "fullchain.pem" | wc -l)
  if [ "$FULLCHAIN_COUNT" -eq 0 ]; then
    err "No fullchain.pem found under ${CERT_DIR}."
    err "Ensure an initial certificate has been issued via certbot."
    PREREQ_FAILED=true
  else
    info "  PASSED — found ${FULLCHAIN_COUNT} certificate(s) under ${CERT_DIR}."
  fi
fi

# --------------------------------------------------------------------------
# Fail hard if any prerequisite check failed
# --------------------------------------------------------------------------
if [ "$PREREQ_FAILED" = true ]; then
  err "========== One or more prerequisite checks FAILED. Aborting. =========="
  send_slack_notification \
    ":x: *SSL Renewal Aborted* on \`$(hostname)\`.\nOne or more prerequisite checks failed before renewal could start.\nCheck logs: \`${LOG_FILE}\`" \
    "danger"
  exit 1
fi

info "========== All prerequisite checks PASSED =========="

# ==========================================================================
# MAIN RENEWAL LOGIC
# ==========================================================================

# --------------------------------------------------------------------------
# Step 1: Find the certificate and extract domain
# --------------------------------------------------------------------------
info "Starting SSL certificate expiry check..."

FULLCHAIN_PATH=$(find "$CERT_DIR" -maxdepth 2 -name "fullchain.pem" | head -n 1)
info "Found certificate at: ${FULLCHAIN_PATH}"

# Extract the non-wildcard domain from SAN
DOMAIN=$(sudo openssl x509 -in "$FULLCHAIN_PATH" -noout -text \
  | grep -A 1 "Subject Alternative Name:" \
  | tail -n 1 \
  | sed 's/ *DNS://g')

MOSIP_DOMAIN=$(echo "$DOMAIN" | tr ',' '\n' | sed 's/^[[:space:]]*//' | grep -v '^\*' | head -n 1)

if [ -z "$MOSIP_DOMAIN" ]; then
  err "Could not extract domain from certificate at ${FULLCHAIN_PATH}."
  send_slack_notification \
    ":x: *SSL Check FAILED* on \`$(hostname)\`.\nCould not parse domain from certificate." \
    "danger"
  exit 1
fi

info "Domain: ${MOSIP_DOMAIN}"

# --------------------------------------------------------------------------
# Step 2: Check expiry date
# --------------------------------------------------------------------------
EXPIRY_DATE=$(sudo openssl x509 -enddate -noout -in "$FULLCHAIN_PATH" | sed 's/notAfter=//')
EXPIRY_EPOCH=$(date --date="$EXPIRY_DATE" +%s)
NOW_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

info "Certificate expiry : ${EXPIRY_DATE}"
info "Days until expiry  : ${DAYS_UNTIL_EXPIRY}"

if (( DAYS_UNTIL_EXPIRY > DAYS_THRESHOLD )); then
  info "Certificate is valid for ${DAYS_UNTIL_EXPIRY} more days. No renewal needed."
  # Use kill to exit the main process cleanly, bypassing the tee subshell
  kill -TERM $$
fi

# --------------------------------------------------------------------------
# Step 3: Renewal needed — notify Slack and proceed
# --------------------------------------------------------------------------
info "Certificate expires in ${DAYS_UNTIL_EXPIRY} days. Starting renewal..."

send_slack_notification \
  ":warning: *SSL Renewal Started* for \`${MOSIP_DOMAIN}\` on \`$(hostname)\`.\nCertificate expires in *${DAYS_UNTIL_EXPIRY} days* (${EXPIRY_DATE}).\nAttempting renewal now..." \
  "warning"

# --------------------------------------------------------------------------
# Step 4: Renew using certbot with --cert-name
# --cert-name ensures certbot updates the existing live/ symlinks in place
# No manual mv needed — certbot handles the archive and symlink update
# --------------------------------------------------------------------------
info "Running certbot renewal for ${MOSIP_DOMAIN}..."

sudo certbot certonly \
  --dns-route53 \
  --dns-route53-propagation-seconds 30 \
  --cert-name "$MOSIP_DOMAIN" \
  --agree-tos \
  --non-interactive \
  -d "$MOSIP_DOMAIN" \
  -d "*.$MOSIP_DOMAIN"

info "Certbot completed successfully."

# --------------------------------------------------------------------------
# Step 5: Verify the new cert was actually issued and symlinks resolve
# --------------------------------------------------------------------------
NEW_EXPIRY=$(sudo openssl x509 -enddate -noout -in "$FULLCHAIN_PATH" | sed 's/notAfter=//')
NEW_EXPIRY_EPOCH=$(date --date="$NEW_EXPIRY" +%s)
info "New certificate expiry: ${NEW_EXPIRY}"

# Certbot may skip renewal if it decides the cert is not yet due (< 30 days
# remaining by certbot's own threshold). If that happens, treat it as a
# warning rather than a hard failure — the cert is still valid.
if [ "$NEW_EXPIRY_EPOCH" -le "$EXPIRY_EPOCH" ]; then
  warn "Certbot did not issue a new certificate (expiry unchanged)."
  warn "This can happen if certbot's own 30-day threshold has not been reached."
  warn "Current expiry: ${NEW_EXPIRY} (${DAYS_UNTIL_EXPIRY} days away)."
  send_slack_notification \
    ":warning: *SSL Renewal Skipped* for \`${MOSIP_DOMAIN}\` on \`$(hostname)\`.\nCertbot did not renew — cert still valid until *${NEW_EXPIRY}* (${DAYS_UNTIL_EXPIRY} days).\nNo action needed." \
    "warning"
  exit 0
fi

# --------------------------------------------------------------------------
# Step 6: Reload nginx gracefully (no dropped connections)
# --------------------------------------------------------------------------
info "Reloading nginx..."
sudo systemctl reload nginx
info "Nginx reloaded successfully."

# --------------------------------------------------------------------------
# Step 7: Success notification
# --------------------------------------------------------------------------
RENEWAL_SUCCESS=true
send_slack_notification \
  ":white_check_mark: *SSL Certificate Renewed Successfully* for \`${MOSIP_DOMAIN}\` on \`$(hostname)\`.\nPrevious expiry: ${EXPIRY_DATE}\nNew expiry: *${NEW_EXPIRY}*." \
  "good"

info "SSL renewal process completed successfully."
