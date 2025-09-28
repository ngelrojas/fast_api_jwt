terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "5.0"
        }
    }
    backend "s3" {
      bucket = var.bucket_name
      key = "terraform/state/production.tfstate"
      region = var.aws_region
      dynamodb_table = var.table_name
      encrypt = true
    }
}
provider "aws" {
    region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

module "s3-storage" {
    source = "./s3-storage"
}

module "iam" {
    source = "./iam"
    s3_bucket_name = module.s3-storage.storage_files_csv.bucket
    s3_bucket_arn  = module.s3-storage.storage_files_csv.arn
}

module "sqs-notifications" {
    source = "./sqs-notifications"
}

module "ec2-api" {
    source = "./ec2-fast-api-jwt"
}

module "ec2-self-hosted" {
  source = "./ec2-self-hosted"
  vpc_id = data.aws_vpc.default.id
  github_token = var.github_token
  github_repo = var.github_repo
  self_hosted_runner_role_name = module.iam.self_hosted_runner_role_name
  self_hosted_runner_role_id   = module.iam.self_hosted_runner_role_id
  storage_files_csv = {
    bucket = module.s3-storage.storage_files_csv.bucket
    arn    = module.s3-storage.storage_files_csv.arn
  }
}
