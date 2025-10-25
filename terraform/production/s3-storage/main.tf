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

resource "aws_s3_bucket_policy" "storage_files_csv_policy" {
  bucket = aws_s3_bucket.storage_files_csv.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { "AWS" : "*" },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.storage_files_csv.arn}/*"
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
