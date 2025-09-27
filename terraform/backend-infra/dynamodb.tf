resource "aws_dynamodb_table" "terraform_locks" {
  name = var.dynamodb_table_name
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    dynamic "point_in_time_recovery" {
      for_each = var.enable_point_in_time_recovery ? [1] : []
      content {
          enabled = true
      }
    }
    tags = {
      Name        = "terraform-locks-${var.environment}"
      Environment = var.environment
    }
}
