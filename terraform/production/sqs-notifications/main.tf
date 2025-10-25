resource "aws_sqs_queue" "file_upload_queue" {
  name = var.sqs_queue_name

  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 day
  tags = {
    Environment = var.environment
    Project     = var.file_upload_queue_tag_prj
    Purpose     = var.file_upload_queue_tag_purpose
  }
}

# SQS Queue Policy to allow S3 to send messages
resource "aws_sqs_queue_policy" "file_upload_queue_policy" {
  queue_url = aws_sqs_queue.file_upload_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.file_upload_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::storage-files-csv"
          }
        }
      }
    ]
  })
}
