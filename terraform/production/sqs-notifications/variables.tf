variable "sqs_queue_name" {
  description = "The name of the SQS queue to receive notifications"
  type        = string
  default     = "file-upload-queue"
}

variable "environment" {
  description = "The environment for the SQS queue"
  type        = string
  default     = "production"
}
variable "file_upload_queue_tag_name" {
  description = "Tag name for the SQS file upload queue"
  type        = string
  default     = "fast-api-jwt-queue"
}
variable "file_upload_queue_tag_description" {
  description = "Tag description for the SQS file upload queue"
  type        = string
  default     = "file-upload-notifications-sqs"
}
variable "file_upload_queue_tag_prj" {
  description = "project name"
  type        = string
  default     = "fast-api-jwt"
}
variable "file_upload_queue_tag_purpose" {
  description = "purpose of the resource"
  type        = string
  default     = "file-upload-notifications"
}
