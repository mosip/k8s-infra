#!/bin/bash

# Prompt the user for the domain name
read -p "Enter the domain name: " mosip_domain

expiry_date=$(sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/$mosip_domain/fullchain.pem)
echo "SSL certificate expiry date: $expiry_date"

# Convert the expiry date to a cron format (minute hour day month)
# Ensure the date is in a parseable format for the date command
# Extract the day, month, and year
day=$(echo "$expiry_date" | awk '{print $2}')
month=$(echo "$expiry_date" | awk '{print $1}' | cut -d= -f2)
year=$(echo "$expiry_date" | awk '{print $4}')

# Convert month name to month number
case $month in
  Jan) month_num=1 ;;
  Feb) month_num=2 ;;
  Mar) month_num=3 ;;
  Apr) month_num=4 ;;
  May) month_num=5 ;;
  Jun) month_num=6 ;;
  Jul) month_num=7 ;;
  Aug) month_num=8 ;;
  Sep) month_num=9 ;;
  Oct) month_num=10 ;;
  Nov) month_num=11 ;;
  Dec) month_num=12 ;;
  *) echo "Invalid month"; exit 1 ;;
esac

# Construct the cron time string
cron_time="0 6 $day $month_num *"

# Print the cron time (for verification)
echo "Cron time: $cron_time"

# Define the command you want to run on the expiry date
command_to_run="renew_certificates.sh"

# Create a cron job
(crontab -l; echo "$cron_time $command_to_run") | crontab -

echo "Scheduled job for $cron_time to run at 6am."