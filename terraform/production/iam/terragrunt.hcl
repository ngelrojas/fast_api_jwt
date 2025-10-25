# Terragrunt configuration for IAM module
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

# Dependencies - IAM needs S3 bucket info
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

inputs = {
  s3_bucket_name = dependency.s3.outputs.storage_files_csv.bucket
  s3_bucket_arn  = dependency.s3.outputs.storage_files_csv.arn
}
