# Terragrunt configuration for EC2 FastAPI JWT module
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

# Dependencies
dependency "s3" {
  config_path = "../s3-storage"

  mock_outputs = {
    storage_files_csv = {
      bucket = "mock-bucket"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "iam" {
  config_path = "../iam"

  mock_outputs = {
    ec2_ssm_role = "mock-role"
    ec2_ssm_profile = {
      name = "mock-profile"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "secrets" {
  config_path = "../secret-manager"

  mock_outputs = {
    secret_name = "mock-secret"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  storage_files_csv    = dependency.s3.outputs.storage_files_csv.bucket
  ec2_ssm_role         = dependency.iam.outputs.ec2_ssm_role
  secret_name          = dependency.secrets.outputs.secret_name
  ec2_instance_profile = dependency.iam.outputs.ec2_ssm_profile.name
}
