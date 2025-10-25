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
variable "bucket_name" {
  description = "S3 bucket name for application data"
  type        = string
  default     = ""
}
variable "table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = ""
}

# Secret Manager Variables
variable "secret_key" {
  description = "Secret key for JWT encoding"
  type        = string
  sensitive   = true
}

variable "algorithm" {
  description = "Algorithm for JWT encoding"
  type        = string
  default     = "HS256"
}

variable "user_name" {
  description = "Application username"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Application password"
  type        = string
  sensitive   = true
}

variable "url_base" {
  description = "Base URL for the application"
  type        = string
  default     = "http://localhost:8000"
}
