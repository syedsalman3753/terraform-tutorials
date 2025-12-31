terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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
  region = "ap-south-1"
}

variable EC2_NAME {
  type = string
  default = "terraform-test1-ec2"
}
variable CLUSTER_NAME {
  type = string
  default = "SOIL"
}

resource "aws_instance" "EC2_NAME" {
  ami           = "ami-0a7cf821b91bcccbc"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
file -s /dev/xvdb
mkfs -t xfs /dev/xvdb
mkdir /srv/nfs/
echo "/dev/xvdb    /srv/nfs/ xfs  defaults,nofail  0  2" >> /etc/fstab
mount -a
EOF
  tags = { 
    Name = var.EC2_NAME
    Cluster = var.CLUSTER_NAME
  }
  security_groups = [
    "launch-wizard-69"
  ]
  vpc_security_group_ids = [
    "sg-03cb9c04efaa60db8"
  ]
  root_block_device {
    volume_size = 30 # in GB <<----- I increased this!
    volume_type = "gp3"
    delete_on_termination = true
    encrypted   = false
    #kms_key_id  = data.aws_kms_key.customer_master_key.arn
    tags = {
      Nane = var.EC2_NAME
      Cluster = var.CLUSTER_NAME
    }
  }
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = 10
    delete_on_termination = true
    encrypted = false
    tags = {
      Nane = var.EC2_NAME
      Cluster = var.CLUSTER_NAME
    }

  }
}

output "public_ip" {
  value = aws_instance.EC2_NAME.public_ip
}
output "private_ip" {
  value = aws_instance.EC2_NAME.private_ip
}


