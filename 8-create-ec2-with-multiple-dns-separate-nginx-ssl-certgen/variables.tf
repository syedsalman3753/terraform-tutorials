variable "AWS_PROVIDER_REGION" { type = string }
variable "CLUSTER_NAME" { type = string }
variable "SSH_KEY_NAME" { type = string }
variable "SECURITY_GROUP" {
  type = map(list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
    }
  )))
}
variable "K8S_INSTANCE_TYPE" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]+\\..*", var.K8S_INSTANCE_TYPE))
    error_message = "Invalid instance type format. Must be in the form 'series.type'."
  }
}
variable "AMI" {
  type = string
  validation {
    condition     = can(regex("^ami-[a-f0-9]{17}$", var.AMI))
    error_message = "Invalid AMI format. It should be in the format 'ami-xxxxxxxxxxxxxxxxx'"
  }
}
variable "NGINX_INSTANCE_TYPE" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]+\\..*", var.NGINX_INSTANCE_TYPE))
    error_message = "Invalid instance type format. Must be in the form 'series.type'."
  }
}
variable "MOSIP_DOMAIN" { type = string }
variable "ZONE_ID" { type = string }

# NGINX TAG NAME VARIABLE
locals {
  TAG_NAME = {
    NGINX_TAG_NAME = "${var.CLUSTER_NAME}-NGINX-NODE"
  }
  NGINX_CERTS = {
    CLUSTER_NGINX_CERTS    = "/etc/letsencrypt/live/${var.MOSIP_DOMAIN}/fullchain.pem"
    CLUSTER_NGINX_CERT_KEY = "/etc/letsencrypt/live/${var.MOSIP_DOMAIN}/privkey.pem"
  }
}


# DNS CONFIGURATION
locals {
  MAP_DNS_TO_IP = {
    API_DNS = {
      name    = "api.${var.MOSIP_DOMAIN}"
      type    = "A"
      zone_id = var.ZONE_ID
      ttl     = 300
      records = aws_instance.NGINX_EC2_INSTANCE.tags.Name == local.TAG_NAME.NGINX_TAG_NAME ? aws_instance.NGINX_EC2_INSTANCE.public_ip : ""
      #health_check_id = true
      allow_overwrite = true
    }
    API_INTERNAL_DNS = {
      name    = "api-internal.${var.MOSIP_DOMAIN}"
      type    = "A"
      zone_id = var.ZONE_ID
      ttl     = 300
      records = aws_instance.NGINX_EC2_INSTANCE.tags.Name == local.TAG_NAME.NGINX_TAG_NAME ? aws_instance.NGINX_EC2_INSTANCE.private_ip : ""
      #health_check_id = true
      allow_overwrite = true
    }
  }
}
locals {
  MAP_DNS_TO_CNAME = {
    MOSIP_HOMEPAGE_DNS = {
      name    = var.MOSIP_DOMAIN
      type    = "CNAME"
      zone_id = var.ZONE_ID
      ttl     = 300
      records = local.MAP_DNS_TO_IP.API_INTERNAL_DNS.name
      #health_check_id = true
      allow_overwrite = true
    }
    ADMIN_DNS = {
      name    = "admin.${var.MOSIP_DOMAIN}"
      type    = "CNAME"
      zone_id = var.ZONE_ID
      ttl     = 300
      records = local.MAP_DNS_TO_IP.API_INTERNAL_DNS.name
      #health_check_id = true
      allow_overwrite = true
    }
    PREREG_DNS = {
      name    = "prereg.${var.MOSIP_DOMAIN}"
      type    = "CNAME"
      zone_id = var.ZONE_ID
      ttl     = 300
      records = local.MAP_DNS_TO_IP.API_DNS.name
      #health_check_id = true
      allow_overwrite = true
    }
  }
}


# EC2 INSTANCE DATA: NGINX & K8S NODES
locals {
  NGINX_INSTANCE = {
    ami                         = var.AMI
    instance_type               = var.NGINX_INSTANCE_TYPE
    associate_public_ip_address = true
    key_name                    = var.SSH_KEY_NAME
    user_data =<<-EOF
#!/bin/bash

# Log file path
echo "[ Set Log File ] : "
LOG_FILE="/tmp/nginx-ec2-node.log"

# Redirect stdout and stderr to log file
exec > >(tee -a "$LOG_FILE") 2>&1


# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes

## Install Nginx, ssl dependencies
echo "[ Install nginx & ssl dependencies packages ] : "
apt-get update
apt install -y software-properties-common
add-apt-repository universe
apt update
apt-get install nginx letsencrypt certbot python3-certbot-nginx python3-certbot-dns-route53 -y

## Mount EBS volume
echo "[ Mount EBS volume to /srv/nfs directory ] : "
file -s /dev/xvdb
mkfs -t xfs /dev/xvdb
mkdir -p /srv/nfs
echo "/dev/xvdb    /srv/nfs xfs  defaults,nofail  0  2" >> /etc/fstab
mount -a

## Get ssl certificate automatically
sleep 10
echo "[ Generate SSL certificates from letsencrypt  ] : "
certbot certonly --dns-route53 -d "*.${var.MOSIP_DOMAIN}" -d "${var.MOSIP_DOMAIN}" --non-interactive --agree-tos --email syed.salman@technoforte.co.in

## start and enable Nginx
echo "[ Start & Enable nginx ] : "
systemctl enable nginx
systemctl start nginx

##
ENV_FILE_PATH="/home/ubuntu/.env"
echo "export cluster_nginx_internal_ip="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"" >> $ENV_FILE_PATH
echo "export cluster_nginx_public_ip="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"" >> $ENV_FILE_PATH

echo "export cluster_nginx_certs="${local.NGINX_CERTS.CLUSTER_NGINX_CERTS}""               >> $ENV_FILE_PATH
echo "export cluster_nginx_cert_key="${local.NGINX_CERTS.CLUSTER_NGINX_CERT_KEY}""         >> $ENV_FILE_PATH

echo "export cluster_node_ips=$(echo "${join(",", aws_instance.K8S_CLUSTER_EC2_INSTANCE[*].private_ip)}")" >> $ENV_FILE_PATH

echo "export cluster_public_domains=$(echo "${join(",", local.MAP_DNS_TO_CNAME[*].name)}")"    >> $ENV_FILE_PATH

## Set ports configuration
echo "export cluster_ingress_public_nodeport="30080""      >> $ENV_FILE_PATH
echo "export cluster_ingress_internal_nodeport="31080""    >> $ENV_FILE_PATH
echo "export cluster_ingress_postgres_nodeport="31432""    >> $ENV_FILE_PATH
echo "export cluster_ingress_minio_nodeport="30900""       >> $ENV_FILE_PATH
echo "export cluster_ingress_activemq_nodeport="31616""    >> $ENV_FILE_PATH

source $ENV_FILE_PATH
env | grep cluster

cd /home/ubuntu/
git clone https://github.com/syedsalman3753/k8s-infra.git -b main
cd ./k8s-infra/mosip/on-prem/nginx

source $ENV_FILE_PATH

./install.sh

sudo su ubuntu
source $ENV_FILE_PATH
env | grep cluster
exit 0
EOF
    tags = {
      Name    = local.TAG_NAME.NGINX_TAG_NAME
      Cluster = var.CLUSTER_NAME
    }
    security_groups = [
      aws_security_group.security-group["NGINX_SECURITY_GROUP"].id
    ]

    root_block_device = {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = false
      tags = {
        Name    = local.TAG_NAME.NGINX_TAG_NAME
        Cluster = var.CLUSTER_NAME
      }
    }
    ebs_block_device = [{
      device_name           = "/dev/sdb"
      volume_size           = 10
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = false
      tags = {
        Name    = local.TAG_NAME.NGINX_TAG_NAME
        Cluster = var.CLUSTER_NAME
      }
    }]
  }
  K8S_EC2_NODE = {
    ami                         = var.AMI
    instance_type               = var.K8S_INSTANCE_TYPE
    associate_public_ip_address = true
    key_name                    = var.SSH_KEY_NAME
    count                       = 1
    tags = {
      Name    = "${var.CLUSTER_NAME}-node"
      Cluster = var.CLUSTER_NAME
    }
    security_groups = [
      aws_security_group.security-group["K8S_SECURITY_GROUP"].id
    ]

    root_block_device = {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = false

    }
  }
}
