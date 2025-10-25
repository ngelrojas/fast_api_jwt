# Terragrunt configuration for EC2 Self-Hosted Runner module
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

# Get VPC data
dependency "s3" {
  config_path = "../s3-storage"

  mock_outputs = {
    storage_files_csv = {
      bucket = "mock-bucket"
      arn    = "arn:aws:s3:::mock-bucket"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "iam" {
  config_path = "../iam"

  mock_outputs = {
    self_hosted_runner_profile = {
      name = "mock-profile"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  vpc_id                     = get_env("TF_VAR_vpc_id", "")
  github_token               = get_env("TF_VAR_github_token", "")
  github_repo                = get_env("TF_VAR_github_repo", "https://github.com/ngelrojas/fast_api_jwt")
  self_hosted_runner_profile = dependency.iam.outputs.self_hosted_runner_profile.name
  storage_files_csv = {
    bucket = dependency.s3.outputs.storage_files_csv.bucket
    arn    = dependency.s3.outputs.storage_files_csv.arn
  }
}
