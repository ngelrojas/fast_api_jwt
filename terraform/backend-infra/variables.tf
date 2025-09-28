variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The environment to create resources in."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project fast api jwt."
  type        = string
  default     = "fast-api-jwt"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store the Terraform state file."
  type        = string
  default     = "tf-state-lock-bucket-prod"
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table to store the Terraform state locks."
  type        = string
  default     = "terraform-locks-fast-api-jwt"
}

variable "enable_point_in_time_recovery" {
  description = "Enable point in time recovery for the DynamoDB table."
  type        = bool
  default     = true
}
