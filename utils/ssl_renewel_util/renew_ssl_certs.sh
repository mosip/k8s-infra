#!/bin/bash
# Script to renew ssl certificates..

# Log file path
log_file="ssl_cert_renewal.log"

# Redirect stdout and stderr to the log file
exec > >(tee -a "$log_file") 2>&1

function ssl_certs_renew() {
  # Get the current date to backup the existing ssl certs directory with current date
  suffix=$(date +"%d-%m-%Y")

  # Define the source and destination directories
  src_dir="/etc/letsencrypt/live"
  dest_dir="/etc/letsencrypt/live-${suffix}"

  # Check if the source directory exists
  if [ -d "$src_dir" ]; then
      # Move the directory
      sudo mv "$src_dir" "$dest_dir"
      echo "Directory moved to $dest_dir"
  else
      echo "Source directory $src_dir does not exist."
  fi

  # Regenerate the ssl certificates

  # Fetch the domain from the ssl certs
  domain=$(sudo openssl x509 -in $dest_dir/*/fullchain.pem -noout -text | grep -A 1 "Subject Alternative Name:" | tail -n 1 | sed 's/ *DNS://g')
  mosip_domain=$(echo "$domain" | tr ',' '\n' | grep -v '^\*' | head -n 1)

  # Check if the domain is not empty
  if [ -z "$mosip_domain" ]; then
      echo "Domain name cannot be empty"
      exit 1
  fi

  # Run certbot with the user-provided domain name
  sudo certbot certonly \
    --dns-route53 \
    -d "$mosip_domain" \
    -d "*.$mosip_domain"

  # Rename the new certificates
  sudo mv /etc/letsencrypt/live/$mosip_domain-* /etc/letsencrypt/live/$mosip_domain

  # Slack notification for ssl certs renew
  # Slack webhook URL
  slack_webhook_url="https://hooks.slack.com/services/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"

  # Notification message
  message="SSL certificate for "$mosip_domain" has been successfully renewed."

  # Send notification to Slack
  curl -X POST -H 'Content-type: application/json' --data "{
      \"text\": \"$message\"
  }" "$slack_webhook_url"

  # Restart the Nginx service
  sudo systemctl restart nginx
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
ssl_certs_renew