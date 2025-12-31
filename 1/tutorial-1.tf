variable name {
  type=string
  #default="NA"
}
variable age {
  type=number
  #default="0"
  description = "age should be between 0 to 110"
  validation {
    condition = (
      var.age >= 0 && var.age < 110
    )
    error_message = "Valid values for variable `age` is between `0` to `110`."
  }
}
variable score {
  type=number
  #default="0"
  description = "age should be between 0 to 110"
  validation {
    condition = (
    var.score >= 0 && var.score < 100
    )
    error_message = "Valid values for variable `score` is between `0` to `100`."
  }
}


output output1 {
  value = "\tName: \"${var.name}\"\n\tAge: \"${var.age}\"\n\tScore: \"${var.score}%\"\n\tLocation: \"${var.location}\""
}

output output2 {
  value = "Testing is completed !!!"
}
