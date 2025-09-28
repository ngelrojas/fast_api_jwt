# Data
data "terraform_remote_state" "s3_storage" {
  backend = "local"
    config = {
        path = "../s3-storage/terraform.tfstate"
    }
}
data "terraform_remote_state" "iam" {
  backend = "local"
    config = {
        path = "../iam/terraform.tfstate"
    }
}
# Variables
variable "aws_region" {
  description = "AWS region to deploy EC2 instance"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key name for EC2 instance"
  type        = string
  default     = "self-hosted-key-github"
}

variable "vpc_id" {
  description = "VPC ID for EC2 instance"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository (e.g. owner/repo)"
  type        = string
  default     = "https://github.com/ngelrojas/fast_api_jwt"
}

variable "github_token" {
  description = "GitHub Actions runner registration token"
  type        = string
  sensitive   = true
}

variable "storage_files_csv" {
  default = data.terraform_remote_state.s3_storage.outputs.storage_files_csv
}
variable "ec2_tag_name" {
    description = "Tag name for the EC2 instance"
    type        = string
    default     = "github-actions-self-hosted"
}
variable "service_name" {
    description = "Service name for tagging"
    type        = string
    default     = "github-actions-runner"
}
variable "environment" {
    description = "Environment for tagging"
    type        = string
    default     = "production"
}
variable "project_name" {
    description = "Project name for tagging"
    type        = string
    default     = "fast-api-jwt"
}
variable "self_hosted_runner_profile" {
  default = data.terraform_remote_state.iam.outputs.self_hosted_runner_profile
}
