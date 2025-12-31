#!/bin/bash

# Log file path
LOG_FILE="/tmp/nginx_ec2_node.log"

# Redirect stdout and stderr to log file
exec > >(tee -a "$LOG_FILE") 2>&1


# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes

## Install Nginx, ssl dependencies
apt-get update
apt-get install nginx letsencrypt certbot python3-certbot-nginx -y
systemctl enable nginx
systemctl start nginx

## Mount EBS volume
file -s /dev/xvdb
mkfs -t xfs /dev/xvdb
mkdir -p /srv/nfs
echo "/dev/xvdb    /srv/nfs xfs  defaults,nofail  0  2" >> /etc/fstab
mount -a