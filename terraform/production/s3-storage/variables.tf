# Variables
variable "s3_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "storage-files-csv"
}
variable "environment" {
  description = "The environment for the S3 bucket"
  type        = string
  default     = "production"
}
variable "expiration_day" {
  description = "Number of days after which objects are deleted"
  type        = number
  default     = 30 # Automatically delete objects older than 30 days
}

variable "sqs_queue_name" {
  description = "The name of the SQS queue for file uploads"
  type        = string
  default     = "file-upload-queue"
}
