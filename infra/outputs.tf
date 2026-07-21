// Root outputs exposing critical values for CI and users
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ec2_instance_id" {
  value = module.app_ec2.instance_id
}

output "ec2_public_ip" {
  value = module.app_ec2.instance_public_ip
}
