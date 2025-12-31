variable tag {
  type = string
}

variable location {
  type = string
  #default = "dd"
}

output location {
 value = var.location
}
