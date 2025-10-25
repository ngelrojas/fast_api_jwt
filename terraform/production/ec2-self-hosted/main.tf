data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "aws-aim-ubuntu-fast-api-jwt"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

locals {
  docker_user_data = templatefile("${path.module}/self_hosted.sh", {
    region          = var.aws_region
    app_data_bucket = var.storage_files_csv.bucket
    github_token    = var.github_token
    github_repo     = var.github_repo
  })
}
resource "aws_security_group" "github_actions_runner" {
  name        = var.github_actions_runner_name
  description = var.github_actions_runner_description
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
resource "aws_instance" "github_actions_runner" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  security_groups      = [aws_security_group.github_actions_runner.name]
  iam_instance_profile = var.self_hosted_runner_profile

  user_data = local.docker_user_data

  tags = {
    Name        = var.ec2_tag_name
    Service     = var.service_name
    Environment = var.environment
    Project     = var.project_name
  }
}
