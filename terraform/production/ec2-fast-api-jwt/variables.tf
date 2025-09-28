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
  default = data.terraform_remote_state.s3_storage.outputs.storage_files_csv
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
  default = data.terraform_remote_state.iam.outputs.ec2_ssm_role
}
variable "policy_arn" {
    description = "The ARN of the policy to attach to the role"
    type        = string
    default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
