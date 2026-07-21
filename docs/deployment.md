# Deployment Guide

## Prerequisites

Before deploying, ensure you have:

- ✅ AWS Account (Free Tier eligible)
- ✅ Terraform v1.0+
- ✅ AWS CLI v2
- ✅ Docker (for local testing)
- ✅ Git
- ✅ An SSH key pair in AWS (optional)

## Step-by-Step Deployment

### Phase 1: Local Setup

#### 1.1 Clone Repository

```bash
git clone https://github.com/yourusername/nextjs-aws-ec2-deployment.git
cd nextjs-aws-ec2-deployment
```

#### 1.2 Install Dependencies

```bash
cd app
npm install
npm run build  # Test that the app builds locally
cd ..
```

#### 1.3 Test Locally with Docker

```bash
# Build the Docker image
docker build -t nextjs-local .

# Run the container
docker run -p 3000:3000 nextjs-local

# Visit http://localhost:3000
```

### Phase 2: AWS Setup

#### 2.1 Configure AWS Credentials

```bash
# Option 1: AWS CLI
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Format (json)

# Option 2: Environment Variables
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
```

Verify credentials:
```bash
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

#### 2.2 Create SSH Key Pair (Optional but Recommended)

```bash
# Create key pair in AWS
aws ec2 create-key-pair --key-name my-ssh-key --region us-east-1 \
  --query 'KeyMaterial' --output text > my-ssh-key.pem

# Set permissions
chmod 400 my-ssh-key.pem

# Verify it exists
aws ec2 describe-key-pairs --region us-east-1
```

### Phase 3: Terraform Deployment

#### 3.1 Initialize Terraform

```bash
cd infra
terraform init
```

This downloads AWS provider plugins and initializes `.terraform/` directory.

#### 3.2 Create Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region         = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
instance_type       = "t2.micro"
ecr_repo_name       = "nextjs-app-repo"
ssh_key_name        = "my-ssh-key"          # <- Use the key created above
image_tag           = "latest"
```

**If not using SSH**, set `ssh_key_name = ""`

#### 3.3 Validate Configuration

```bash
terraform validate
terraform fmt -recursive  # Format code nicely
```

#### 3.4 Plan Deployment

```bash
terraform plan -out plan.tfplan
```

This shows what resources will be created. Review the output carefully.

Expected resources:
- 1 VPC
- 1 Public Subnet
- 1 Internet Gateway
- 1 Route Table
- 1 Security Group
- 1 EC2 Instance
- 1 IAM Role & Instance Profile
- 1 ECR Repository

#### 3.5 Apply Infrastructure

```bash
terraform apply plan.tfplan
```

Confirm by typing `yes` when prompted.

This usually takes 2-3 minutes.

#### 3.6 Save Outputs

```bash
terraform output
```

Save these values - you'll need them later:
- `ecr_repository_url`: ECR repo full URL
- `ec2_public_ip`: Your EC2 instance's public IP
- `ec2_instance_id`: EC2 instance ID

Example output:
```
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/nextjs-app-repo"
ec2_public_ip = "52.123.45.67"
ec2_instance_id = "i-0123456789abcdef0"
```

### Phase 4: Verify Infrastructure

#### 4.1 Check EC2 Instance

```bash
# List instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name]' \
  --output table
```

#### 4.2 Check ECR Repository

```bash
aws ecr describe-repositories --repository-names nextjs-app-repo
```

#### 4.3 SSH into EC2 (if using SSH key)

```bash
ssh -i my-ssh-key.pem ec2-user@<EC2_PUBLIC_IP>
```

Commands to run on EC2:
```bash
# Check Docker is running
sudo systemctl status docker

# View running containers
docker ps

# Check logs
docker logs nextjs-app

# Exit
exit
```

### Phase 5: GitHub Actions Setup

#### 5.1 Get Your AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

Save this 12-digit number.

#### 5.2 Create GitHub Repository

```bash
cd ..  # Back to project root
git init
git add .
git commit -m "Initial commit: production-ready Next.js deployment"
git branch -M main
git remote add origin https://github.com/yourusername/nextjs-aws-ec2-deployment.git
git push -u origin main
```

#### 5.3 Add GitHub Secrets

Go to: **GitHub → your repo → Settings → Secrets and variables → Actions**

Click **New repository secret** and add these 8 secrets:

| Secret Name | Value | Where to Get |
|-------------|-------|--------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | `aws configure` or IAM console |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | IAM console |
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account ID | `aws sts get-caller-identity` |
| `AWS_REGION` | `us-east-1` | Same region as Terraform |
| `ECR_REPOSITORY` | `nextjs-app-repo` | Same as `ecr_repo_name` in terraform.tfvars |
| `EC2_HOST` | EC2 public IP | Terraform outputs or AWS console |
| `EC2_USER` | `ec2-user` | Default for Amazon Linux 2 |
| `EC2_SSH_KEY` | Private key content | `cat my-ssh-key.pem` (paste entire content) |

**⚠️ NEVER share these secrets publicly!**

#### 5.4 Verify GitHub Secrets

```bash
# List secrets (you'll see masked values)
# This is in GitHub UI only, not via CLI
```

### Phase 6: First Deployment

#### 6.1 Trigger CI/CD

```bash
# Make a small change to the code
echo "# First deployment" >> README.md

# Commit and push
git add README.md
git commit -m "First deployment test"
git push origin main
```

#### 6.2 Monitor GitHub Actions

1. Go to GitHub repo → **Actions** tab
2. Click the running workflow
3. Monitor each step:
   - ✅ Checkout
   - ✅ Configure AWS credentials
   - ✅ Login to ECR
   - ✅ Build Docker image
   - ✅ Push to ECR
   - ✅ Deploy to EC2

#### 6.3 Verify Deployment

Once workflow completes with ✅:

```bash
# SSH into EC2
ssh -i my-ssh-key.pem ec2-user@<EC2_PUBLIC_IP>

# Check container is running
docker ps
docker logs -f nextjs-app

# Exit SSH
exit
```

Visit your application:
```
http://<EC2_PUBLIC_IP>
```

You should see your Next.js app! 🎉

### Phase 7: Subsequent Deployments

For every code change, just push to main:

```bash
# Make code changes
echo "New feature" >> README.md

# Commit and push
git add .
git commit -m "Add new feature"
git push origin main
```

GitHub Actions will automatically:
1. Build the Docker image
2. Push to ECR
3. Deploy to EC2

## Troubleshooting Deployments

### Terraform Apply Fails

```bash
# Validate syntax
terraform validate

# Check credentials
aws sts get-caller-identity

# See detailed error
terraform apply -var-file=terraform.tfvars -verbose
```

### GitHub Actions Fails

**Check workflow logs** (Actions tab → click workflow run)

Common issues:
- `Invalid GitHub Secrets` - Verify all 8 secrets are set correctly
- `SSH connection timed out` - EC2 security group doesn't allow port 22 from GitHub
- `ECR authentication failed` - AWS credentials are wrong or expired

### Container Not Running on EC2

```bash
# SSH into EC2
ssh -i my-ssh-key.pem ec2-user@<EC2_PUBLIC_IP>

# Check Docker status
sudo systemctl status docker

# View all containers (including stopped)
docker ps -a

# Check logs
docker logs nextjs-app

# Restart container
docker restart nextjs-app

# Exit SSH
exit
```

### Application Displays 502 Gateway Error

- Port mapping might be wrong
- Check security group allows traffic on port 80
- Verify container is running: `docker ps`
- Check logs: `docker logs nextjs-app`

## Rollback & Recovery

### Rollback to Previous Image

```bash
# List ECR images
aws ecr describe-images --repository-name nextjs-app-repo \
  --query 'imageDetails[*].[imageTags,imagePushedAt]' --output table

# SSH into EC2
ssh -i my-ssh-key.pem ec2-user@<EC2_PUBLIC_IP>

# Pull older image by tag (if tagged)
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/nextjs-app-repo:v1.0.0

# Stop current container
docker stop nextjs-app
docker rm nextjs-app

# Run old image
docker run -d --name nextjs-app --restart unless-stopped -p 80:3000 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/nextjs-app-repo:v1.0.0

# Verify
docker ps
```

### Scale Down Infrastructure

```bash
cd infra
terraform destroy
# Type 'yes' to confirm
```

This removes all AWS resources and stops billing.

## Best Practices

✅ **Do:**
- Enable AWS CloudWatch for monitoring
- Set up billing alerts in AWS Budgets
- Rotate SSH keys periodically
- Keep Terraform state backed up
- Use semantic versioning for Docker images
- Monitor GitHub Actions usage

❌ **Don't:**
- Commit `.env` or `terraform.tfvars`
- Use production credentials for testing
- Leave SSH open to 0.0.0.0/0 in production
- Store secrets in code
- Use `admin` IAM policies
- Skip security group reviews

---

**Next Steps:**
- Read [Architecture](./architecture.md) for system design details
- Check [Security](./security.md) for best practices
- View [Troubleshooting](./troubleshooting.md) for common issues
