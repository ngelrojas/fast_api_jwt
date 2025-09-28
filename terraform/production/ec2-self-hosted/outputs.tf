output "instance_id" {
  value = aws_instance.github_actions_runner.id
}

output "public_ip" {
  value = aws_instance.github_actions_runner.public_ip
}

output "public_dns" {
  value = aws_instance.github_actions_runner.public_dns
}
