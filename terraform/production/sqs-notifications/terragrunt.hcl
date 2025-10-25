# Terragrunt configuration for SQS Notifications module
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

inputs = {
  # Add any SQS-specific variables here
  environment = "production"
}
