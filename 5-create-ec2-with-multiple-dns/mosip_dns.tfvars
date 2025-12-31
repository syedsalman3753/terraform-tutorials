NGINX_EC2_NAME      = "TERRAFORM_TEST1"
CLUSTER_NAME        = "TERRAFORM-TESTING"
AWS_PROVIDER_REGION = "ap-south-1"
SSH_KEY_NAME        = "mosip-aws"
EBS_VOLUME_NAME     = "/dev/xvdb"
EBS_VOLUME_PATH     = "/srv/nfs/"
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
    from_port : 22,
    to_port : 22,
    protocol : "TCP",
    cidr_blocks      = ["0.0.0.0/0"],
    ipv6_cidr_blocks = ["::/0"]
  }
]


