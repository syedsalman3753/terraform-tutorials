$ terraform plan -var output1=tyu -out output1=\{type=string\,value='hi'\}

variable output1 {
type=string
//default="ttt"
}
output output1 {
value="printing ${var.output1}"
}


=================
$ terraform apply -input=false -auto-approve
`-auto-approve` - will not prompt for `yes` for terraform apply
`-input=false`  - will not prompt for input variables



================
$ export TF_VAR_age=56

$ terraform apply -auto-approve
# terraform will automatically look for env vars and if the variables have TF_VAR_xxxx
# it will automatically take it as an tarraform variable
....
....
output1 = <<EOT
	    Name: "fff"
	    Age: "56"
	    Score: "34%"
	    Location: "eee"
    EOT
