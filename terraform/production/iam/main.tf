resource "aws_iam_role" "ec2_ssm_role" {
  name = var.ec2_ssm_fast_api
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Effect = "Allow",
            Principal = {
            Service = "ec2.amazonaws.com"
            },
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
