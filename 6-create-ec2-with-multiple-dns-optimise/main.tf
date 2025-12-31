terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }
  }
}

# provider "aws" {
# Profile `default` means it will take credentials AWS_SITE_KEY & AWS_SECRET_EKY from ~/.aws/config under `default` section.
# profile = "default"
# region = "ap-south-1"
# }
provider "aws" {
  region = var.AWS_PROVIDER_REGION
}

resource "aws_security_group" "mosip-nginx-sg" {

  tags = {
    Name    = "mosip-nginx-sg"
    Cluster = var.CLUSTER_NAME
  }
  description = "Allow tcp ports for nginx load balancer MOSIP"

  dynamic "ingress" {
    for_each = var.NGINX_SECURITY_GROUP
    iterator = port
    content {
      description      = ""
      from_port        = port.value.from_port
      to_port          = port.value.to_port
      protocol         = port.value.protocol
      cidr_blocks      = port.value.cidr_blocks
      ipv6_cidr_blocks = port.value.ipv6_cidr_blocks
    }
  }
}

resource "aws_instance" "EC2_INSTANCE" {
  for_each = local.EC2_CONFIG

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  associate_public_ip_address = lookup(each.value,"associate_public_ip_address",false)
  key_name                    = each.value.key_name
  user_data                   = lookup(each.value,"user_data","")
  vpc_security_group_ids      = each.value.security_groups

  root_block_device {
    volume_size           = each.value.root_block_device.volume_size
    volume_type           = each.value.root_block_device.volume_type
    delete_on_termination = each.value.root_block_device.delete_on_termination
    encrypted             = each.value.root_block_device.encrypted
    tags                  = each.value.root_block_device.tags
  }

  dynamic "ebs_block_device" {
    for_each = each.value.ebs_block_device
    iterator = ebs_volume
    content {
      device_name           = ebs_volume.value.device_name
      volume_size           = ebs_volume.value.volume_size
      volume_type           = ebs_volume.value.volume_type
      delete_on_termination = ebs_volume.value.delete_on_termination
      encrypted             = ebs_volume.value.encrypted
      tags                  = ebs_volume.value.tags
    }
  }

  tags = {
    Name    = each.value.tags.Name
    Cluster = each.value.tags.Cluster
  }
}

resource "aws_route53_record" "MAP_DNS_TO_IP" {
 for_each = local.MAP_DNS_TO_IP
 name     = each.value.name
 type     = each.value.type
 zone_id  = each.value.zone_id
 ttl      = each.value.ttl
 records  = [each.value.records]
 #health_check_id = true
 allow_overwrite = each.value.allow_overwrite
}
resource "aws_route53_record" "MAP_DNS_TO_CNAME" {
 for_each = local.MAP_DNS_TO_CNAME
 name     = each.value.name
 type     = each.value.type
 zone_id  = each.value.zone_id
 ttl      = each.value.ttl
 records  = [each.value.records]
 #health_check_id = true
 allow_overwrite = each.value.allow_overwrite
}


output "public_ip" {
  value = { for key, instance in aws_instance.EC2_INSTANCE : key => instance.public_ip }
}
output "private_ip" {
  value = { for key, instance in aws_instance.EC2_INSTANCE : key => instance.private_ip }
}

output "mosip-nginx-sg_id" {
  value = aws_security_group.mosip-nginx-sg.id
}