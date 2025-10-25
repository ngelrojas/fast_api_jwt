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

# Reference the existing GitHub Actions OIDC role
data "aws_iam_role" "github_actions_role" {
  name = var.github_actions_role_name
}

# Attach Secrets Manager permissions to the GitHub Actions role
resource "aws_iam_role_policy" "github_actions_secrets_manager" {
  name = "github-actions-secrets-manager-access"
  role = data.aws_iam_role.github_actions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:ListSecrets",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:DeleteResourcePolicy",
          "secretsmanager:RestoreSecret",
          "secretsmanager:RotateSecret",
          "secretsmanager:CancelRotateSecret",
          "secretsmanager:ValidateResourcePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach S3 permissions to the GitHub Actions role for infrastructure management
resource "aws_iam_role_policy" "github_actions_s3_management" {
  name = "github-actions-s3-management-access"
  role = data.aws_iam_role.github_actions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketNotification",
          "s3:PutBucketNotification",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetBucketAcl",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::storage-files-csv",
          "arn:aws:s3:::storage-files-csv/*",
          "arn:aws:s3:::terraform-state-*",
          "arn:aws:s3:::terraform-state-*/*"
        ]
      }
    ]
  })
}
