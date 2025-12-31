variable instance_type {
  type = string
}

output instance_type {
  value = "EC2 instance type : ${var.instance_type}\n EC2 instance tag : ${var.tag}\n EC2 location : ${var.location}"
}