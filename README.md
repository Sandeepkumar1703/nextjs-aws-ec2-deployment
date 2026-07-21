# nextjs-aws-ec2-deployment

[![GitHub](https://img.shields.io/badge/GitHub-nextjs--aws--ec2--deployment-blue?logo=github)](https://github.com/yourusername/nextjs-aws-ec2-deployment)
[![Terraform](https://img.shields.io/badge/Terraform-v1.0+-blue?logo=terraform)](https://www.terraform.io/)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage-blue?logo=docker)](https://www.docker.com/)
[![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20ECR%20%7C%20VPC-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Next.js](https://img.shields.io/badge/Next.js-Latest-black?logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0%2B-blue?logo=typescript)](https://www.typescriptlang.org/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue?logo=github-actions)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

Production-ready DevOps project demonstrating how to deploy a Next.js application to AWS using only Free Tier eligible services. This project showcases modern DevOps practices including Infrastructure as Code (Terraform), containerization (Docker), and automated CI/CD (GitHub Actions).

**Perfect for portfolios, learning, and small production deployments!**

---

## Key Features

- **Next.js + TypeScript**: Modern React framework with type safety
- **Multi-stage Docker build**: Optimized container images (~150MB)
- **Non-root container**: Runs as unprivileged user for enhanced security
- **Terraform (Modular)**: Infrastructure as Code with reusable modules
- **Amazon ECR**: Private Docker registry for container images
- **GitHub Actions**: Automated CI/CD pipeline
- **Free Tier Eligible**: Uses only AWS free tier services (where possible)
- **No EKS/Kubernetes**: Simplified deployment using EC2

## Quick Links

📚 **Documentation**
- [Architecture Overview](./docs/architecture.md) - System design, data flow, security architecture
- [Deployment Guide](./docs/deployment.md) - Step-by-step setup instructions
- [Troubleshooting Guide](./docs/troubleshooting.md) - Common issues and solutions
- [Security Guide](./docs/security.md) - Best practices and security recommendations

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  (Next.js App + Terraform + GitHub Actions Workflow)        │
└────────┬────────────────────────────────────────────────────┘
         │ Push to main
         ↓
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions CI/CD Pipeline                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ 1. Checkout code                                        │ │
│  │ 2. Configure AWS credentials                           │ │
│  │ 3. Build Docker image                                  │ │
│  │ 4. Push to Amazon ECR                                  │ │
│  │ 5. Connect to EC2 via SSH                             │ │
│  │ 6. Pull latest image & restart container              │ │
│  └─────────────────────────────────────────────────────────┘ │
└────────┬──────────────────────────────────────┬──────────────┘
         │                                      │
         ↓                                      ↓
   ┌──────────────┐                    ┌──────────────┐
   │ Amazon ECR   │                    │ AWS EC2      │
   │ Repository   │                    │ Instance     │
   │              │                    │              │
   │ Docker       │────Pull Image──→   │ Docker       │
   │ Images       │                    │ Container    │
   └──────────────┘                    └──────┬───────┘
                                              │
                                              ↓
                                        ┌──────────────┐
                                        │ Port 80      │
                                        │ Next.js App  │
                                        │ (Port 3000)  │
                                        └──────────────┘
```

## Prerequisites

- **AWS Account**: Free Tier eligible (t2.micro instance, ECR)
- **Terraform**: v1.0 or higher
- **AWS CLI**: v2 (optional, for manual deployments)
- **Docker**: For local development and building images
- **Git**: For repository management
- **SSH Key Pair**: Optional but recommended for EC2 access

## Project Structure

```
nextjs-aws-ec2-deployment/
├── app/                              # Next.js application
│   ├── package.json                 # Node dependencies
│   ├── tsconfig.json                # TypeScript configuration
│   └── pages/
│       └── index.tsx                # Next.js home page
├── infra/                            # Terraform infrastructure
│   ├── provider.tf                  # AWS provider configuration
│   ├── variables.tf                 # Input variables
│   ├── terraform.tfvars.example     # Example variables (copy to terraform.tfvars)
│   ├── outputs.tf                   # Output values
│   ├── security.tf                  # Security configurations
│   ├── main.tf                      # Root module
│   └── modules/
│       ├── ec2/                     # EC2 instance module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── user_data.tpl        # EC2 startup script
│       └── network/                 # VPC & networking module
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── scripts/
│   └── install_docker.sh            # Docker installation script
├── .github/
│   └── workflows/
│       └── ci-cd.yml                # GitHub Actions CI/CD pipeline
├── Dockerfile                        # Multi-stage Docker build
├── docker-compose.yml               # Local development setup
├── .dockerignore                    # Files excluded from Docker build
├── .gitignore                       # Files excluded from Git
├── .env.example                     # Environment variables template
├── package.json                     # Root package.json (scripts)
└── README.md                        # This file
```

## Quick Start (Local Development)

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/nextjs-aws-ec2-deployment.git
cd nextjs-aws-ec2-deployment
```

### 2. Install Next.js dependencies

```bash
cd app
npm install
```

### 3. Build and run locally with Docker Compose

```bash
# From the project root
docker-compose up --build
# Visit http://localhost:3000
```

### 4. Or develop without Docker

```bash
cd app
npm run dev
# Visit http://localhost:3000
```

## AWS Deployment with Terraform

### 1. Prerequisites for Terraform

- AWS credentials configured locally:
  ```bash
  aws configure
  # or set environment variables:
  export AWS_ACCESS_KEY_ID=your-key
  export AWS_SECRET_ACCESS_KEY=your-secret
  export AWS_REGION=us-east-1
  ```

- Create an SSH key pair in AWS (optional, for SSH access):
  ```bash
  aws ec2 create-key-pair --key-name my-ssh-key --region us-east-1 --query 'KeyMaterial' --output text > my-ssh-key.pem
  chmod 400 my-ssh-key.pem
  ```

### 2. Initialize Terraform

```bash
cd infra
terraform init
```

### 3. Create terraform.tfvars

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Example `terraform.tfvars`:
```hcl
aws_region         = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
instance_type       = "t2.micro"
ecr_repo_name       = "nextjs-app-repo"
ssh_key_name        = "my-ssh-key"  # Leave empty if not using SSH
image_tag           = "latest"
```

### 4. Plan and review infrastructure

```bash
terraform plan -out plan.tfplan
```

### 5. Apply infrastructure

```bash
terraform apply plan.tfplan
```

After completion, note the outputs:
- `ecr_repository_url`: Your ECR repository URL
- `ec2_public_ip`: Public IP of your EC2 instance

### 6. Verify EC2 instance is running

```bash
# SSH into your instance (if you provided ssh_key_name)
ssh -i my-ssh-key.pem ec2-user@<EC2_PUBLIC_IP>

# Check Docker is running
docker ps

# Monitor the application
docker logs -f nextjs-app
```

## CI/CD with GitHub Actions

### 1. Set GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

```
AWS_ACCESS_KEY_ID          → Your AWS access key
AWS_SECRET_ACCESS_KEY      → Your AWS secret key
AWS_ACCOUNT_ID             → Your AWS account ID (e.g., 123456789012)
AWS_REGION                 → AWS region (e.g., us-east-1)
ECR_REPOSITORY             → ECR repo name (e.g., nextjs-app-repo)
EC2_HOST                   → Public IP or DNS of EC2 instance
EC2_USER                   → EC2 user (e.g., ec2-user for Amazon Linux 2)
EC2_SSH_KEY                → Private SSH key content (cat my-ssh-key.pem)
```

### 2. Push to main branch

```bash
git push origin main
```

### 3. Monitor workflow

- Go to Actions tab in GitHub
- Watch the workflow execute
- Check EC2 instance for running container: `docker logs -f nextjs-app`

## Environment Variables

### Application Environment Variables

Create `.env.local` in the `app/` directory (or root `.env` for Next.js):

```bash
# Copy from .env.example
cp .env.example .env.local
```

### Terraform Variables

Copy from `terraform.tfvars.example`:
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

**Important**: `.env`, `terraform.tfvars`, and `.pem` files are in `.gitignore` and should never be committed.

## Security Best Practices

### 1. Container Security

- ✅ **Non-root user**: Container runs as `nextjs:nodejs` (UID 1001) instead of root
- ✅ **Multi-stage build**: Reduces final image size and excludes build dependencies
- ✅ **ECR image scanning**: Enabled to detect vulnerabilities

### 2. Infrastructure Security

- ✅ **IAM roles**: EC2 instance uses IAM role with ECR read-only access
- ✅ **Security groups**: Restrict SSH access (configure CIDR blocks, not 0.0.0.0/0 for production)
- ✅ **No hardcoded credentials**: Uses AWS IAM roles and GitHub Secrets
- ✅ **Private ECR repository**: Docker images stored in private ECR

### 3. CI/CD Security

- ✅ **GitHub Secrets**: All credentials stored as encrypted secrets
- ✅ **SSH key-based deployment**: Container deployment via SSH, not HTTP
- ✅ **Read-only IAM permissions**: ECR access limited to pull operations

### 4. Production Recommendations

For production deployments, consider:

**Security Group:**
```hcl
# Instead of allowing SSH from anywhere:
# cidr_blocks = ["0.0.0.0/0"]

# Use a specific IP range or Bastion host:
# cidr_blocks = ["YOUR_OFFICE_IP/32"]
# or use AWS Systems Manager Session Manager instead of SSH
```

**GitHub Actions:**
- Use AWS OIDC for temporary credentials instead of long-lived keys
- Rotate SSH keys regularly
- Monitor CloudTrail for deployment activities

**EC2:**
- Enable CloudWatch monitoring and alarms
- Use AWS Systems Manager Session Manager instead of SSH
- Apply OS security patches regularly

**Container Registry:**
- Enable ECR image scanning
- Implement image signing with Docker Content Trust
- Set lifecycle policies to clean old images

## Cost Optimization Notes

### Free Tier Eligible (as of 2024)

- **EC2**: t2.micro (750 hours/month for 12 months)
- **ECR**: 0.50 USD per GB-month (first 500 GB/month free tier varies)
- **Data Transfer**: Free ingress, 1GB/month free egress
- **CloudWatch**: Limited free logs

### Estimated Monthly Cost (after free tier)

```
Scenario: t2.micro EC2 + ECR (10GB storage) + Data transfer (5GB/month)

t2.micro (beyond free tier):    $0.00-10.00 USD
ECR storage (10GB):             $5.00 USD
ECR API calls:                  $0.50 USD
Data transfer (outbound 5GB):   $1.00 USD
────────────────────────────────────────────
Total (approximate):            $6.50-16.50 USD/month
```

### Cost Reduction Strategies

1. **Use Auto Shutdown**: Stop EC2 when not needed
2. **Monitor with AWS Budgets**: Set alerts for cost anomalies
3. **Cleanup unused resources**: Run `terraform destroy` when not using
4. **Optimize ECR**: Delete old images, use lifecycle policies
5. **Direct Connect alternatives**: Use VPC endpoints instead of NAT

## Terraform Commands Reference

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan deployment
terraform plan -out plan.tfplan

# Apply deployment
terraform apply plan.tfplan

# Destroy infrastructure (clean up)
terraform destroy

# View outputs
terraform output

# View Terraform state (read-only)
terraform state list
terraform state show aws_instance.app
```

## Docker Commands Reference

```bash
# Build local image
docker build -t local-nextjs .

# Run locally
docker run -p 3000:3000 local-nextjs

# Build with Docker Compose
docker-compose up --build

# View running containers
docker ps

# View logs
docker logs -f nextjs-app

# SSH into running container
docker exec -it nextjs-app sh
```

## Troubleshooting

### Terraform Issues

**Error: "Error putting S3 Backend Bucket versioning"**
```bash
# Solution: Ensure AWS credentials are valid
aws sts get-caller-identity
```

**Error: "Error: No EC2 images found with matching name"**
```bash
# Solution: Verify region supports Amazon Linux 2 AMI
terraform plan -var="aws_region=us-east-1"
```

### GitHub Actions CI/CD Issues

**Error: "SSH connection timed out"**
- Verify EC2 instance has elastic IP or public IP
- Check security group allows SSH (port 22)
- Verify EC2_USER is correct (ec2-user for Amazon Linux 2)

**Error: "Docker image not found in ECR"**
- Verify IMAGE_URI in workflow output
- Check ECR repository name matches ECR_REPOSITORY secret
- Ensure AWS credentials have ECR access

### EC2 Container Issues

**Check container logs:**
```bash
ssh -i my-ssh-key.pem ec2-user@<IP>
docker logs nextjs-app
docker logs -f --tail 50 nextjs-app
```

**Restart container:**
```bash
docker restart nextjs-app
```

**View running processes:**
```bash
docker ps -a
docker inspect nextjs-app
```

## Cleanup

### Remove all AWS infrastructure

```bash
cd infra
terraform destroy
```

When prompted, type `yes` to confirm deletion of all resources.

### Clean local Docker

```bash
docker-compose down
docker image remove local-nextjs
docker system prune -a  # Remove all unused images and containers
```

## Notes

- **No AWS account hardcoding**: Uses `data.aws_caller_identity` to dynamically fetch account ID
- **Modular Terraform**: Separate network and EC2 modules for reusability
- **Production-ready workflow**: Multi-stage Docker build, non-root user, security best practices
- **Free Tier optimization**: Uses t2.micro and other free tier services where applicable

## Security Review Checklist

Before pushing to GitHub, verify:

- ✅ No `.env` files committed (only `.env.example`)
- ✅ No `terraform.tfvars` committed (only `terraform.tfvars.example`)
- ✅ No `.pem` or `.key` files committed
- ✅ No AWS credentials in code or workflow definitions
- ✅ `.gitignore` includes all sensitive files
- ✅ GitHub Secrets configured for all credentials
- ✅ README includes security best practices
- ✅ Terraform uses IAM data source (no account ID hardcoding)

## License

MIT

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
