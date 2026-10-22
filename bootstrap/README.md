# bootstrap

Creates the storage account that holds Terraform state for every environment.
Run it **once**, before anything else:

```bash
cd bootstrap
terraform init
terraform apply
terraform output backend_config
```

Copy the values into `envs/dev.backend.hcl`, `envs/staging.backend.hcl` and `envs/prod.backend.hcl`.

This folder keeps local state because it creates the place remote state lives.
The storage account has versioning and soft delete on, account keys off (Entra ID only),
and a delete lock.
