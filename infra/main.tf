// Root module that composes network and EC2 modules and creates ECR repository
// This file wires modules together and creates shared resources

locals {
  // derived values
}

// Data source to discover caller account id (no hardcoding)
data "aws_caller_identity" "current" {}

// Create ECR repository to host built images
resource "aws_ecr_repository" "app" {
  name = var.ecr_repo_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.ecr_repo_name
  }
}

// Create network resources via module
module "network" {
  source             = "./modules/network"
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
}

// Determine a suitable Amazon Linux 2 AMI for the region
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

// EC2 module to create instance, IAM role, and run container
module "app_ec2" {
  source        = "./modules/ec2"
  aws_region    = var.aws_region
  ami_id        = data.aws_ami.al2.id
  instance_type = var.instance_type
  subnet_id     = module.network.public_subnet_id
  vpc_id        = module.network.vpc_id
  key_name      = var.ssh_key_name
  ecr_repo_url  = aws_ecr_repository.app.repository_url
  image_tag     = var.image_tag
  account_id    = data.aws_caller_identity.current.account_id
}
