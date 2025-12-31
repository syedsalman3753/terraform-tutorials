CLUSTER_NAME        = "TERRAFORM-TESTING"
AWS_PROVIDER_REGION = "ap-south-1"
SSH_KEY_NAME        = "mosip-aws"

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
    description : "SSH login port"
    from_port : 80,
    to_port : 80,
    protocol : "TCP",
    cidr_blocks      = ["0.0.0.0/0"],
    ipv6_cidr_blocks = ["::/0"]
  },
  {
    description : "SSH login port"
    from_port : 443,
    to_port : 443,
    protocol : "TCP",
    cidr_blocks      = ["0.0.0.0/0"],
    ipv6_cidr_blocks = ["::/0"]
  }
]

