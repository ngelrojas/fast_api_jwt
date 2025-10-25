# Terragrunt configuration for Secret Manager module
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

inputs = {
  # Sensitive variables should be set via environment variables or AWS Parameter Store
  # For example: export TF_VAR_secret_key="your-secret-key"
  secret_key = get_env("TF_VAR_secret_key", "")
  user_name  = get_env("TF_VAR_user_name", "")
  password   = get_env("TF_VAR_password", "")
  url_base   = get_env("TF_VAR_url_base", "http://localhost:8000")
}
