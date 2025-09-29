resource "aws_sqs_queue" "file_upload_queue" {
  name = var.sqs_queue_name

  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 day
  tags = {
    Environment = var.environment
    Project     = "fast-api-jwt"
    Purpose     = "file-upload-notifications"
  }
}
