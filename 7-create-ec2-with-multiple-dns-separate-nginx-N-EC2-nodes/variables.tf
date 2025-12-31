variable "AWS_PROVIDER_REGION" {
  type = string
}
variable "CLUSTER_NAME" {
  type = string
}
variable "SSH_KEY_NAME" {
  type = string
}
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

variable "MOSIP_DOMAIN" {
  type = string
}
variable "ZONE_ID" {
  type = string
}


# NGINX TAG NAME VARIABLE
locals {
  TAG_NAME = {
    NGINX_TAG_NAME = "${var.CLUSTER_NAME}-NGINX-NODE"
  }
}

# EC2 INSTANCE DATA: NGINX & K8S NODES
locals {
  NGINX_INSTANCE = {
    ami                         = var.AMI
    instance_type               = var.NGINX_INSTANCE_TYPE
    associate_public_ip_address = true
    key_name                    = var.SSH_KEY_NAME
    user_data                   = file("nginx_node_userdata.sh")
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
    associate_public_ip_address = false
    key_name                    = var.SSH_KEY_NAME
    count                       = 2
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
