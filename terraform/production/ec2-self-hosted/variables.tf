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
  description = "VPC ID for EC2 instance (uses default VPC if not specified)"
  type        = string
  default     = ""
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
  description = "S3 bucket details for storage files CSV"
  type = object({
    bucket = string
    arn    = string
  })
  default = {
    bucket = "storage-files-csv"
    arn    = "arn:aws:s3:::storage-files-csv"
  }
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
  description = "IAM instance profile for the self-hosted GitHub Actions runner"
  type        = string
  default     = "self-hosted-role"
}
variable "ubuntu_name_aim" {
  description = "aim name for ubuntu AMI"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04"
}
variable "github_actions_runner_name" {
  description = "GitHub Actions runner security group"
  type        = string
  default     = "github-actions-self-hosted-sg"
}
variable "github_actions_runner_description" {
  description = "Description for GitHub Actions runner security group"
  type        = string
  default     = "Allow SSH and GitHub Actions runner traffic"
}
