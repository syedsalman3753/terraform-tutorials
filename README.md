# terraform-tutorials

## Installation

* Follow the instructions provided [here](https://developer.hashicorp.com/terraform/install) to install Terraform according to your operating system.
  ```
  $ terraform -v
    Terraform v1.8.2
    on linux_amd64
  ```

## Tutorials

1. Introduction to `Infrastructure as Code (IAC)`

If you want to delete only one object
```
terraform destroy -target=<provider>.<object>
```

```
terraform destroy -target=github_repository.test_2
```

terraform init, validate, provider, plan, refresh, destroy, -auto-approve
terraform fmt