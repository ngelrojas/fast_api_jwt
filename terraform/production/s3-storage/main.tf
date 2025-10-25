# Data source to fetch the SQS queue ARN
data "aws_sqs_queue" "file_upload_queue" {
  name = var.sqs_queue_name
}

resource "aws_s3_bucket" "storage_files_csv" {
  bucket = var.s3_name
  tags = {
    Name        = var.s3_name
    Environment = var.environment
    Project     = "storage"
    Purpose     = "files-csv"
  }
}

resource "aws_s3_bucket_public_access_block" "storage_files_csv_block" {
  bucket = aws_s3_bucket.storage_files_csv.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage_files_csv_encryption" {
  bucket = aws_s3_bucket.storage_files_csv.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "storage_files_csv_lifecycle" {
  bucket = aws_s3_bucket.storage_files_csv.id

  rule {
    id     = "delete-old-files"
    status = "Enabled"

    expiration {
      days = var.expiration_day
    }
    filter {
      prefix = "" # Applies to all objects
    }
  }
}

# S3 bucket policy to allow access from specific IAM roles and S3 service
resource "aws_s3_bucket_policy" "storage_files_csv_policy" {
  bucket = aws_s3_bucket.storage_files_csv.id

  # Ensure bucket policy is applied after public access block
  depends_on = [aws_s3_bucket_public_access_block.storage_files_csv_block]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2RoleAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::209479292315:role/ec2-ssm-fast-api",
            "arn:aws:iam::209479292315:role/self-hosted-role"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.storage_files_csv.arn}",
          "${aws_s3_bucket.storage_files_csv.arn}/*"
        ]
      },
      {
        Sid    = "AllowS3NotificationToSQS"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "s3:GetBucketNotification"
        Resource = aws_s3_bucket.storage_files_csv.arn
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "files_csv_notification" {
  bucket = aws_s3_bucket.storage_files_csv.id

  queue {
    queue_arn     = data.aws_sqs_queue.file_upload_queue.arn
    events        = ["s3:ObjectCreated:Put"]
    filter_prefix = ".csv"
  }
  depends_on = [aws_s3_bucket_policy.storage_files_csv_policy]
}
