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
