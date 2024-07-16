#!/bin/bash

# Fetch the domain from the ssl certs
domain=$(sudo openssl x509 -in /etc/letsencrypt/live/*/fullchain.pem -noout -text | grep -A 1 "Subject Alternative Name:" | tail -n 1 | sed 's/ *DNS://g')
mosip_domain=$(echo "$domain" | tr ',' '\n' | grep -v '^\*' | head -n 1)

# Fetch the expiry date from the ssl certs and get the date 7 days before the expiry date to run ssl renew script
expiry_date=$(sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/*/fullchain.pem | sed -e 's/notAfter=//g')

# Convert the expiry date to a cron format (minute hour day month)
# Extract the date and month from the expiry date
adjusted_date=$(date --date="$expiry_date -7 days" +'%d %m')
echo "ssl renew scripts will be exicuted on this day of the month: $adjusted_date"

# Construct the cron time using adjusted_date variable to schedule a cronjob
cron_time="0 0 $adjusted_date *"

# Print the cron time (for verification)
echo "Cron time: $cron_time"

# Create a cron job to exicute the renew_certificates.sh script on the expiry date without manual intervention
echo "$cron_time ./renew_certificates" | crontab -

echo "Scheduled job for $cron_time to run at 12am."