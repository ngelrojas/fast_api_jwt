# Terragrunt configuration for S3 Storage module
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

# Dependencies - this module needs SQS to exist first
dependency "sqs" {
  config_path = "../sqs-notifications"

  # Mock outputs for validation
  mock_outputs = {
    file_upload_queue = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  s3_name           = "storage-files-csv-${get_env("USER", "default")}-prod"
  environment       = "production"
  expiration_day    = 30
  file_upload_queue = dependency.sqs.outputs.file_upload_queue
}
