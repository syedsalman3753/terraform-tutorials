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
    Name : "mosip-nginx-sg"
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


resource "aws_instance" "NGINX_EC2_INSTANCE" {
  ami                         = "ami-0a7cf821b91bcccbc"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = var.SSH_KEY_NAME
  user_data                   = <<EOF
#!/bin/bash
file -s ${var.EBS_VOLUME_NAME}
mkfs -t xfs ${var.EBS_VOLUME_NAME}
mkdir ${var.EBS_VOLUME_PATH}
echo "${var.EBS_VOLUME_NAME}    ${var.EBS_VOLUME_PATH} xfs  defaults,nofail  0  2" >> /etc/fstab
mount -a
EOF
  tags = {
    Name    = var.NGINX_EC2_NAME
    Cluster = var.CLUSTER_NAME
  }
  security_groups = [
    aws_security_group.mosip-nginx-sg.name
  ]
  #vpc_security_group_ids = [
  #  aws_security_group.mosip-nginx-sg.id
  #]
  root_block_device {
    volume_size           = 30 # in GB <<----- I increased this!
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false
    #kms_key_id  = data.aws_kms_key.customer_master_key.arn
    tags = {
      Nane    = var.NGINX_EC2_NAME
      Cluster = var.CLUSTER_NAME
    }
  }
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    encrypted             = false
    tags = {
      Nane    = var.NGINX_EC2_NAME
      Cluster = var.CLUSTER_NAME
    }

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
  value = aws_instance.NGINX_EC2_INSTANCE.public_ip
}
output "private_ip" {
  value = aws_instance.NGINX_EC2_INSTANCE.private_ip
}
output "mosip-nginx-sg_id" {
  value = aws_security_group.mosip-nginx-sg.id
}