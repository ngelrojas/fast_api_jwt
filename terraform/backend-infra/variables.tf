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
