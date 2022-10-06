# Backup and Restore SSL Letsencrypt certificates

1. Backup SSL Letsencrypt certificate
2. Restore SSL Letsencrypt certificate


## Backup SSL Letsencrypt certificate

* Run `download-certs.sh` script on your local machine to back up the SSL Letsencrypt certificate.
  ```
  cd ../utils/
  ```
  ```
  ./backup-certs.sh
  ```
* The Letsencrypt zip file will be copied to the current working directory on your local machine.




## Restore SSL Letsencrypt certificate

* Run `upload-certs.sh` script on your local machine to restore the SSL Letsencrypt certificate.
```
  cd ../utils/
  ```
  ```
  ./restore-certs.sh
  ```
* The Letsencrypt zip file will be restored to the remote node `/etc/letsecrypt`.