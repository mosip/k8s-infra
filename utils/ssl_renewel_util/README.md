# SSL Certificate Renewal Script for Aws
Note: If you are not using Route 53 from Aws as your Dns provider then this script won't work. You'll have to manually renew the certificates, In case if you are using any other Dns provider then check if certbot supports any dns plugin for your Dns provider and then just update the certbot command within the script then the `renew_ssl_certs` script should work fine.

This script is used for the renew of SSL certificates using Let's Encrypt's `certbot`. It moves old certificates to a backup directory with an expiry date and renew the ssl certificates and Update cert directory name.

## Prerequisites

- **Certbot**: Ensure `certbot` is installed and configured on your nginx server.
- **AWS Route 53**: The script uses Route 53 for DNS challenges.
- **Sudo Privileges**: Required to move directories and restart services.
- **Nginx**: Ensure Nginx is installed and configured to use Let's Encrypt certificates.

## Installation

1. **Install Certbot**: Follow the instructions [here](https://certbot.eff.org/instructions) to install `certbot` for your nginx server.
2. **Configure AWS Route 53**: Ensure your domain's DNS is managed by AWS Route 53 and that you have the necessary permissions to perform DNS validation.
3. Configure AWS CLI (Using Root User or IAM User with Full Access)
Run the following command to configure AWS CLI:
    ```sh
    aws configure
    ```
   Configure your aws account using the above command by providing `Access_key_id` and `Secret_access_key`. Make sure you have right access to Route 53 service so that dns records can be added and verfified by let's-encrypt while renewing the ssl certs.
4. Your private and public ssl certificates are assumed to be present in the location "/etc/letsencrypt/live/".
5. **Install the required Packages**:
   ```sh
    sudo apt update
    sudo apt install certbot python3
    sudo apt-get install python3-certbot-dns-route53
    certbot plugins #To list all the certbot plugins
   ```
3. **Script Permissions**: Make sure the script has execute permissions:
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

## Script Overview

The script performs the following steps:

1. Fetches the domain name from the existing ssl certs for which we are trying to renew the certificates.
2. The script fetches the expiry date and Converts the provided expiry date to the appropriate format for scheduling a cron job.
3. Schedules a cron job to run `renew_ssl_certs.sh` at 12am on 7 days before the expiry date.
4. Displays a confirmation message once the job is scheduled in the log file.

## Usage

1. **Make the Script Executable**

   Before running the script, ensure it has executable permissions:

   ```bash
   chmod +x certs_renew_cron.sh
   ```

2. **Run the script**
   
   Run the script with the necessary permissions:

   ```sh
   sudo ./certs_renew_cron.sh 
   ```
   
3. **Verify the Scheduled Cron Job**

   Run the below command to verify the scheduled cronjob with specific date and time.
   
   ```sh
   crontab -l
   ```

## Troubleshooting

* No Crontab for User: If you see no crontab for <user>, it means there are no existing cron jobs for the user. The script will still create the new cron job.
* Invalid Date Format: Ensure you enter the date in YYYY-MM-DD format.
* Permission Issues: Ensure you have the necessary permissions to edit cron jobs for the current user.
* check the log file "ssl_cert_renewal.log" for errors and script failures.
