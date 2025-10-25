terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

module "sqs-notifications" {
  source = "./sqs-notifications"
}

module "s3-storage" {
  source = "./s3-storage"

  # S3 module uses data source to lookup SQS queue by name
  # Explicit dependency ensures SQS queue exists before S3 module runs
  depends_on = [module.sqs-notifications]
}

module "iam" {
  source         = "./iam"
  s3_bucket_name = module.s3-storage.storage_files_csv.bucket
  s3_bucket_arn  = module.s3-storage.storage_files_csv.arn
}

module "secret-manager" {
  source     = "./secret-manager"
  secret_key = var.secret_key
  algorithm  = var.algorithm
  user_name  = var.user_name
  password   = var.password
  url_base   = var.url_base
}

module "ec2-api" {
  source               = "./ec2-fast-api-jwt"
  storage_files_csv    = module.s3-storage.storage_files_csv.bucket
  ec2_ssm_role         = module.iam.ec2_ssm_role.name
  secret_name          = module.secret-manager.secret_name
  ec2_instance_profile = module.iam.ec2_ssm_profile_name
  policy_arn           = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

module "ec2-self-hosted" {
  source                     = "./ec2-self-hosted"
  vpc_id                     = data.aws_vpc.default.id
  github_token               = var.github_token
  github_repo                = var.github_repo
  self_hosted_runner_profile = module.iam.self_hosted_runner_profile_name
  storage_files_csv = {
    bucket = module.s3-storage.storage_files_csv.bucket
    arn    = module.s3-storage.storage_files_csv.arn
  }
}
