resource "aws_iam_role" "ec2_ssm_role" {
  name = var.ec2_ssm_fast_api
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name        = var.ec2_ssm_fast_api_tag
    Environment = var.environment
    Purpose     = "ec2-ssm-role"
  }
}

resource "aws_iam_role_policy" "ec2_secrets_manager_policy" {
  name = "ec2-secrets-manager-access"
  role = aws_iam_role.ec2_ssm_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:fast-api-jwt-credentials-*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${var.ec2_ssm_fast_api}-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_iam_role" "self_hosted_runner" {
  name = var.self_hosted_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "self_hosted_runner_policy" {
  name = var.self_hosted_role
  role = aws_iam_role.self_hosted_runner.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "self_hosted_runner_profile" {
  name = var.self_hosted_role
  role = aws_iam_role.self_hosted_runner.name
}
