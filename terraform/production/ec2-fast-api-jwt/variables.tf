# Variables
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
variable "ec2_ami" {
  description = "EC2 instance type"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type - us-east-1
}
variable "storage_files_csv" {
  description = "S3 bucket for storing files"
  type        = string
  default     = "storage-files-csv"
}
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "ec2_tag_name" {
  description = "Tag Name for the EC2 instance"
  type        = string
  default     = "ec2-fast-api-jwt"
}
variable "service_name" {
  description = "Service name for the application"
  type        = string
  default     = "fast-api-jwt"
}
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "fast-api-jwt"
}
variable "ec2_ssm_role" {
  description = "EC2 IAM Role with SSM access"
  type        = string
  default     = "ec2-ssm-fast-api"
}
variable "ec2_ssm_role_name" {
  description = "EC2 IAM Role name for policy attachment"
  type        = string
  default     = "ec2-ssm-fast-api"
}
variable "policy_arn" {
  description = "The ARN of the policy to attach to the role"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
variable "fast_api_jwt_sg_name" {
  description = "Security Group name for Fast API JWT"
  type        = string
  default     = "fast-api-jwt-sg"
}
variable "fast_api_jwt_sg_description" {
  description = "Security Group description for Fast API JWT"
  type        = string
  default     = "Allow SSH and fast api jwt traffic"
}

variable "secret_name" {
  description = "Name of the AWS Secrets Manager secret"
  type        = string
  default     = "fast-api-jwt-credentials"
}

variable "ec2_instance_profile" {
  description = "IAM instance profile name for EC2 instance"
  type        = string
  default     = "ec2-ssm-fast-api-profile"
}
