variable "AWS_PROVIDER_REGION" {
  type = string
}
variable "CLUSTER_NAME" {
  type    = string
}
variable "SSH_KEY_NAME" {
  type    = string
}
variable "NGINX_SECURITY_GROUP" {
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
    }
  ))
}

locals {
  EC2_CONFIG = {
    EC2_NODE = {
      ami           = "ami-0a7cf821b91bcccbc"
      instance_type = "t2.micro"
      associate_public_ip_address = false
      key_name = var.SSH_KEY_NAME
      tags = {
        Name    = "${var.CLUSTER_NAME}-EC2_NODE"
        Cluster = var.CLUSTER_NAME
      }
      security_groups = [
        aws_security_group.mosip-nginx-sg.id
      ]

      root_block_device = {
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = false
        tags = {
          Name    = "${var.CLUSTER_NAME}-NGINX-NODE"
          Cluster = var.CLUSTER_NAME
        }
      }
      ebs_block_device = []
    }
    NGINX_INSTANCE = {
      ami                         = "ami-0a7cf821b91bcccbc"
      instance_type               = "t2.micro"
      associate_public_ip_address = true
      key_name                    = var.SSH_KEY_NAME
      user_data                   = <<EOF
#!/bin/bash
file -s /dev/xvdb
mkfs -t xfs /dev/xvdb
mkdir -p /srv/nfs
echo "/dev/xvdb    /srv/nfs xfs  defaults,nofail  0  2" >> /etc/fstab
mount -a
EOF
      tags = {
        Name    = "${var.CLUSTER_NAME}-NGINX-NODE"
        Cluster = var.CLUSTER_NAME
      }
      security_groups = [
        aws_security_group.mosip-nginx-sg.id
      ]

      root_block_device = {
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = false
        tags = {
          Name    = "${var.CLUSTER_NAME}-NGINX-NODE"
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
          Name    = "${var.CLUSTER_NAME}-NGINX-NODE"
          Cluster = var.CLUSTER_NAME
        }
      }]
    }
  }
}



locals {
 MAP_DNS_TO_IP = {
   API_DNS = {
     name    = "api.tftest.mosip.net"
     type    = "A"
     zone_id = "Z090954828SJIEL6P5406"
     ttl     = 300
     records = aws_instance.EC2_INSTANCE["NGINX_INSTANCE"].tags.Name == "${var.CLUSTER_NAME}-NGINX-NODE" ? aws_instance.EC2_INSTANCE.public_ip : ""
     #health_check_id = true
     allow_overwrite = true
   }
   API_INTERNAL_DNS = {
     name    = "api-internal.tftest.mosip.net"
     type    = "A"
     zone_id = "Z090954828SJIEL6P5406"
     ttl     = 300
     records = aws_instance.EC2_INSTANCE["NGINX_INSTANCE"].tags.Name == "${var.CLUSTER_NAME}-NGINX-NODE" ? aws_instance.EC2_INSTANCE.private_ip : ""
     #health_check_id = true
     allow_overwrite = true
   }
 }
}
locals {
 MAP_DNS_TO_CNAME = {
   ADMIN_DNS = {
     name    = "admin.tftest.mosip.net"
     type    = "CNAME"
     zone_id = "Z090954828SJIEL6P5406"
     ttl     = 300
     records = local.MAP_DNS_TO_IP.API_INTERNAL_DNS.name
     #health_check_id = true
     allow_overwrite = true
   }
   PREREG_DNS = {
     name    = "prereg.tftest.mosip.net"
     type    = "CNAME"
     zone_id = "Z090954828SJIEL6P5406"
     ttl     = 300
     records = local.MAP_DNS_TO_IP.API_DNS.name
     #health_check_id = true
     allow_overwrite = true
   }
 }
}
