output "ec2_ssm_role" {
  value = aws_iam_role.ec2_ssm_role
}

output "ec2_ssm_profile" {
  value = aws_iam_instance_profile.ec2_ssm_profile
}

output "ec2_ssm_profile_name" {
  value       = aws_iam_instance_profile.ec2_ssm_profile.name
  description = "EC2 IAM instance profile name for SSM"
}

output "self_hosted_runner" {
  value = aws_iam_role.self_hosted_runner
}

output "self_hosted_runner_role_name" {
  value = aws_iam_role.self_hosted_runner.name
}

output "self_hosted_runner_role_id" {
  value = aws_iam_role.self_hosted_runner.id
}
output "self_hosted_runner_profile" {
  value = aws_iam_instance_profile.self_hosted_runner_profile
}
