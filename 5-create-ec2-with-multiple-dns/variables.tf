variable "AWS_PROVIDER_REGION" {
  type = string
}



variable "NGINX_EC2_NAME" {
  type = string
}
variable "CLUSTER_NAME" {
  type = string
}
variable "SSH_KEY_NAME" {
  type = string
}
variable "EBS_VOLUME_NAME" {
  type = string
}
variable "EBS_VOLUME_PATH" {
  type = string
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
  MAP_DNS_TO_IP = {
    API_DNS = {
      name    = "api.tftest.mosip.net"
      type    = "A"
      zone_id = "Z090954828SJIEL6P5406"
      ttl     = 300
      records = aws_instance.NGINX_EC2_INSTANCE.public_ip
      #health_check_id = true
      allow_overwrite = true
    }
    API_INTERNAL_DNS = {
      name    = "api-internal.tftest.mosip.net"
      type    = "A"
      zone_id = "Z090954828SJIEL6P5406"
      ttl     = 300
      records = aws_instance.NGINX_EC2_INSTANCE.private_ip
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
