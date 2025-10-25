data "aws_vpc" "default" {
  default = true
}
locals {
  docker_user_data = templatefile("${path.module}/user_data.sh", {
    region          = var.aws_region
    app_data_bucket = var.storage_files_csv
    secret_name     = var.secret_name
  })
}
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  policy_arn = var.policy_arn
  role       = var.ec2_ssm_role_name
}
resource "aws_security_group" "fast_api_jwt_sg" {
  name        = var.fast_api_jwt_sg_name
  description = var.fast_api_jwt_sg_description
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "fast_api_jwt" {
  ami                  = var.ec2_ami
  instance_type        = var.ec2_instance_type
  security_groups      = [aws_security_group.fast_api_jwt_sg.name]
  iam_instance_profile = var.ec2_instance_profile

  user_data = local.docker_user_data

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
  }

  tags = {
    Name        = var.ec2_tag_name
    Service     = var.service_name
    Environment = var.environment
    Project     = var.project_name
  }
}
