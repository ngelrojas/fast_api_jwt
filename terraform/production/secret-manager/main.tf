# Import block for existing secret (Terraform 1.5+)
import {
  to = aws_secretsmanager_secret.fast_api_credentials
  id = var.secret_name
}

resource "aws_secretsmanager_secret" "fast_api_credentials" {
  name        = var.secret_name
  description = "FastAPI JWT application credentials and configuration"

  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name        = var.secret_name
    Environment = var.environment
    Project     = "fast-api-jwt"
    Purpose     = "application-credentials"
  }

  lifecycle {
    # Prevent accidental deletion of the secret
    prevent_destroy = false
    # If secret already exists, import it instead of recreating
    ignore_changes = []
  }
}

resource "aws_secretsmanager_secret_version" "fast_api_credentials_version" {
  secret_id = aws_secretsmanager_secret.fast_api_credentials.id
  secret_string = jsonencode({
    SECRET    = var.secret_key
    ALGORITHM = var.algorithm
    USER_NAME = var.user_name
    PASSWORD  = var.password
    URL_BASE  = var.url_base
  })
}
