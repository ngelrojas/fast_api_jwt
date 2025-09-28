terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
locals {
  docker_user_data = base64decode(templatefile("user_data.sh", {
    region = var.aws_region
    app_data_bucket = var.storage_files_csv.bucket
  }))
}
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  policy_arn = var.policy_arn
  role       = var.ec2_ssm_role.name
}
resource "aws_instance" "fast_api_jwt" {
  ami = var.ec2_ami
  instance_type = var.ec2_instance_type
  subnet_id = ""
  vpc_security_group_ids = []
  iam_instance_profile = ""

  user_data = local.docker_user_data

  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted = true
  }

  tags = {
    Name = var.ec2_tag_name
    Service = var.service_name
    Environment = var.environment
    Project = var.project_name
  }
}
