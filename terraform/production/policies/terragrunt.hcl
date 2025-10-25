# Terragrunt configuration for Policies module
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

inputs = {
  environment = "production"
}
# Terragrunt configuration for Roles module
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

inputs = {
  environment = "production"
}
