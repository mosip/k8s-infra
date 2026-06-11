#!/bin/bash
# =============================================================================
# setup_ssl_cronjob.sh
# Validates prerequisites and sets up the SSL renewal cron job.
# Run this once on the VM to register the cron job.
# =============================================================================

SCRIPT_NAME="renew_ssl_certs.sh"
SCRIPT_TARGET="/usr/local/bin/${SCRIPT_NAME}"
CRON_FILE="/etc/cron.d/ssl-cert-renewal"
LOG_FILE="/var/log/ssl_cert_renewal.log"

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
info() { log "INFO:  $1"; }
err()  { log "ERROR: $1"; }

info "========== SSL Renewal Cron Setup =========="

# ==========================================================================
# PREREQUISITE CHECKS
# ==========================================================================
info "Running prerequisite checks before registering cron job..."
PREREQ_FAILED=false

# --------------------------------------------------------------------------
# Check 1: Must run as root
# --------------------------------------------------------------------------
info "CHECK 1/6: Sudo / root privileges..."
if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root. Use: sudo bash $0"
  exit 1
fi
info "  PASSED — running as root."

# --------------------------------------------------------------------------
# Check 2: certbot is installed
# --------------------------------------------------------------------------
info "CHECK 2/6: certbot installation..."
if ! command -v certbot &>/dev/null; then
  err "certbot is not installed."
  err "Fix: sudo apt install certbot python3-certbot-dns-route53"
  PREREQ_FAILED=true
else
  CERTBOT_VERSION=$(certbot --version 2>&1)
  info "  PASSED — ${CERTBOT_VERSION}"
fi

# --------------------------------------------------------------------------
# Check 3: certbot Route53 DNS plugin
# --------------------------------------------------------------------------
info "CHECK 3/6: certbot Route53 DNS plugin..."
if ! python3 -c "import certbot_dns_route53" &>/dev/null; then
  err "certbot-dns-route53 plugin is not installed."
  err "Fix: sudo apt install python3-certbot-dns-route53"
  PREREQ_FAILED=true
else
  info "  PASSED — certbot-dns-route53 plugin is available."
fi

# --------------------------------------------------------------------------
# Check 4: AWS Route53 access
# --------------------------------------------------------------------------
info "CHECK 4/6: AWS Route53 access..."
if ! command -v aws &>/dev/null; then
  err "aws CLI not found. Cannot verify Route53 access."
  err "Fix: sudo apt install awscli"
  PREREQ_FAILED=true
else
  if aws route53 list-hosted-zones --output text &>/dev/null; then
    ZONE_COUNT=$(aws route53 list-hosted-zones --query 'length(HostedZones)' --output text 2>/dev/null || echo "unknown")
    info "  PASSED — Route53 accessible. Hosted zones: ${ZONE_COUNT}"
  else
    err "Cannot access Route53 via AWS CLI."
    err "Ensure the EC2 IAM role has these permissions:"
    err "  route53:GetChange, route53:ChangeResourceRecordSets"
    err "  route53:ListHostedZones, route53:ListResourceRecordSets"
    PREREQ_FAILED=true
  fi
fi

# --------------------------------------------------------------------------
# Check 5: nginx is installed and config is valid
# --------------------------------------------------------------------------
info "CHECK 5/6: nginx..."
if ! command -v nginx &>/dev/null; then
  err "nginx is not installed."
  err "Fix: sudo apt install nginx"
  PREREQ_FAILED=true
else
  info "  PASSED — $(nginx -v 2>&1)"
  if ! sudo nginx -t &>/dev/null; then
    err "nginx config test failed. Run 'sudo nginx -t' for details."
    PREREQ_FAILED=true
  else
    info "  PASSED — nginx config is valid."
  fi
fi

# --------------------------------------------------------------------------
# Check 6: renewal script exists at /usr/local/bin/
# --------------------------------------------------------------------------
info "CHECK 6/6: Renewal script at ${SCRIPT_TARGET}..."
if [ ! -f "$SCRIPT_TARGET" ]; then
  err "Renewal script not found at ${SCRIPT_TARGET}."
  err "Fix:"
  err "  sudo cp ${SCRIPT_NAME} ${SCRIPT_TARGET}"
  err "  sudo chmod +x ${SCRIPT_TARGET}"
  PREREQ_FAILED=true
else
  sudo chmod +x "$SCRIPT_TARGET"
  info "  PASSED — script found and marked executable."
fi

# --------------------------------------------------------------------------
# Abort if any check failed
# --------------------------------------------------------------------------
if [ "$PREREQ_FAILED" = true ]; then
  err "========== One or more prerequisite checks FAILED. =========="
  err "Fix the issues above and re-run this script."
  exit 1
fi

info "========== All prerequisite checks PASSED =========="

# ==========================================================================
# SETUP
# ==========================================================================

# --------------------------------------------------------------------------
# Prepare log file
# --------------------------------------------------------------------------
sudo touch "$LOG_FILE"
sudo chmod 644 "$LOG_FILE"
info "Log file ready: ${LOG_FILE}"

# --------------------------------------------------------------------------
# Register the cron job in /etc/cron.d/
# --------------------------------------------------------------------------
sudo tee "$CRON_FILE" > /dev/null <<EOF
# SSL Certificate Renewal Check
# Runs daily at midnight — only renews if expiry is within 7 days
# Managed by: setup_ssl_cronjob.sh
# Logs to: ${LOG_FILE}
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

0 0 * * * root ${SCRIPT_TARGET} >> ${LOG_FILE} 2>&1
EOF

sudo chmod 644 "$CRON_FILE"

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "==========================================="
echo " Cron job registered successfully"
echo "-------------------------------------------"
echo " File    : ${CRON_FILE}"
echo " Schedule: daily at 00:00"
echo " Script  : ${SCRIPT_TARGET}"
echo " Log     : ${LOG_FILE}"
echo "==========================================="
echo ""
echo "Useful commands:"
echo "  View cron entry  : cat ${CRON_FILE}"
echo "  Run manually     : sudo ${SCRIPT_TARGET}"
echo "  Watch logs live  : tail -f ${LOG_FILE}"
echo "  Verify cert      : sudo certbot certificates"
echo ""
