# Root Terragrunt Configuration
# This file contains common configuration that will be inherited by all child terragrunt.hcl files

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project     = "${local.project_name}"
      Environment = "${local.environment}"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "tf-state-locks-fast-api-jwt"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-table-locks-fast-api-jwt"

    # S3 bucket versioning
    s3_bucket_tags = {
      Name        = "Terraform State Storage"
      Environment = "production"
      ManagedBy   = "terragrunt"
    }

    dynamodb_table_tags = {
      Name        = "Terraform Lock Table"
      Environment = "production"
      ManagedBy   = "terragrunt"
    }
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Local variables for reuse
locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl", "empty.hcl"))

  # Extract commonly used variables for easy access
  environment  = try(local.environment_vars.locals.environment, "production")
  aws_region   = try(local.environment_vars.locals.aws_region, "us-east-1")
  project_name = try(local.environment_vars.locals.project_name, "fast-api-jwt")
}

# Configure Terraform version constraints
terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
  }

  # Retry on errors
  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = []
    env_vars = {
      TF_LOG = ""
    }
  }
}

# Input values to pass to modules
inputs = {
  aws_region   = local.aws_region
  environment  = local.environment
  project_name = local.project_name
}
