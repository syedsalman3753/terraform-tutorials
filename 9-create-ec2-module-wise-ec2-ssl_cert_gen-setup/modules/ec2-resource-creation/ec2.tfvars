CLUSTER_NAME        = "TERRAFORM-TESTING"
AWS_PROVIDER_REGION = "ap-south-1"
SSH_KEY_NAME        = "mosip-aws"
K8S_INSTANCE_TYPE   = "t2.micro"
NGINX_INSTANCE_TYPE = "t2.micro"
MOSIP_DOMAIN        = "tftest2.mosip.net"
ZONE_ID             = "Z090954828SJIEL6P5406"
AMI                 = "ami-0a7cf821b91bcccbc"

SECURITY_GROUP = {
  NGINX_SECURITY_GROUP = [
    {
      description : "SSH login port"
      from_port : 22,
      to_port : 22,
      protocol : "TCP",
      cidr_blocks      = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description : "HTTP port"
      from_port : 80,
      to_port : 80,
      protocol : "TCP",
      cidr_blocks      = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description : "HTTPS port"
      from_port : 443,
      to_port : 443,
      protocol : "TCP",
      cidr_blocks      = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
  K8S_SECURITY_GROUP = [
    {
      description : "K8s port"
      from_port : 6443,
      to_port : 6443,
      protocol : "TCP",
      cidr_blocks      = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description : "SSH login port"
      from_port : 22,
      to_port : 22,
      protocol : "TCP",
      cidr_blocks      = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description : "HTTP port"
      from_port : 80,
      to_port : 80,
      protocol : "TCP",
      cidr_blocks      = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description : "HTTPS port"
      from_port : 443,
      to_port : 443,
      protocol : "TCP",
      cidr_blocks      = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
}
