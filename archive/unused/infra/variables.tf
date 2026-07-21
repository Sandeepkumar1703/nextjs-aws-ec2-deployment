// Terraform variables for the deployment
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier friendly default)"
  type        = string
  default     = "t2.micro"
}

variable "ssh_key_name" {
  description = "Existing SSH key pair name in AWS to allow SSH access"
  type        = string
  default     = ""
}

variable "ecr_repo_name" {
  description = "Name for the ECR repository to host container images"
  type        = string
  default     = "nextjs-app-repo"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}
