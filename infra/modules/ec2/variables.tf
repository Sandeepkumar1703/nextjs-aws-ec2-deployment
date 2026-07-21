variable "aws_region" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}
  type    = string
  default = ""
}

variable "ecr_repo_url" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "account_id" {
  type = string
}
