variable "ec2_ssm_fast_api" {
    description = "IAM role name for EC2 with SSM access"
    type        = string
    default     = "ec2-ssm-fast-api"
}
variable "ec2_ssm_fast_api_tag" {
    description = "Tag Name for the IAM role"
    type        = string
    default     = "ec2 ssm fast api"
}
variable "environment" {
    description = "Environment name"
    type        = string
    default     = "production"
}
variable "s3_bucket_name" {
  description = "The name of the S3 bucket for runner policy."
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket for runner policy."
  type        = string
}
