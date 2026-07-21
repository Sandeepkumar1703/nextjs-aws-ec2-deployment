# Troubleshooting Guide

## Common Issues & Solutions

### Terraform Issues

#### Error: "Error: Error putting S3 Backend Bucket versioning"

**Symptom**: Terraform init or apply fails with S3 backend error

**Cause**: AWS credentials are invalid or not configured

**Solution**:
```bash
# Verify credentials are configured
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDA...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-user"
# }

# If error, configure credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID=your-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
```

#### Error: "Error: No EC2 images found with matching name"

**Symptom**: `terraform apply` fails when looking for Amazon Linux 2 AMI

**Cause**: 
- Wrong AWS region specified
- Amazon Linux 2 not available in that region

**Solution**:
```bash
# Verify region is valid
echo $AWS_DEFAULT_REGION

# Check available regions
aws ec2 describe-regions --query 'Regions[*].RegionName' --output table

# Amazon Linux 2 is available in all standard regions except:
# - ap-northeast-3 (Osaka)
# - eu-south-1 (Milan) - partial support

# Use a standard region like us-east-1, us-west-2, eu-west-1
terraform apply -var="aws_region=us-east-1"
```

#### Error: "Error: creating security group: UnauthorizedOperation: You are not authorized to perform this operation"

**Symptom**: IAM user lacks EC2 permissions

**Cause**: IAM policy doesn't include EC2/VPC permissions

**Solution**:
```bash
# Use an IAM user with these policies attached:
# - EC2FullAccess
# - VPCFullAccess
# - IAMFullAccess
# - ECRFullAccess

# Or create a custom policy
aws iam attach-user-policy \
  --user-name your-user \
  --policy-arn arn:aws:iam::aws:policy/EC2FullAccess
```

#### Error: "Key pair 'my-ssh-key' does not exist"

**Symptom**: Terraform apply fails because SSH key was not created in AWS

**Cause**: `ssh_key_name` in `terraform.tfvars` references non-existent key

**Solution**:
```bash
# View existing key pairs
aws ec2 describe-key-pairs --region us-east-1

# Create new key pair
aws ec2 create-key-pair --key-name my-ssh-key --region us-east-1 \
  --query 'KeyMaterial' --output text > my-ssh-key.pem
chmod 400 my-ssh-key.pem

# Or update terraform.tfvars to use correct key name
# Or set ssh_key_name to empty string if not using SSH
```

#### Error: "Error: failed to download providers"

**Symptom**: `terraform init` fails when downloading AWS provider

**Cause**: 
- Network connectivity issue
- Terraform version mismatch
- Proxy blocking downloads

**Solution**:
```bash
# Clear cache and retry
rm -rf .terraform/
terraform init

# Or use explicit provider version
terraform init -upgrade

# If behind proxy, configure it
export HTTP_PROXY=http://proxy:port
export HTTPS_PROXY=https://proxy:port
terraform init
```

---

### GitHub Actions Issues

#### Workflow Error: "Pull request trigger not available on private repositories"

**Symptom**: Workflow file syntax error

**Cause**: GitHub Actions limits vary by public/private repos

**Solution**: The workflow should already be correct. Check `.github/workflows/ci-cd.yml`:
```yaml
on:
  push:
    branches: [ main ]  # ✅ Correct

# Not:
on:
  pull_request:        # May have issues with private repos
```

#### Error: "Missing required GitHub Secrets"

**Symptom**: Workflow fails with message about undefined secrets

**Cause**: One or more GitHub Secrets are not configured

**Solution**:
```bash
# Go to GitHub repo → Settings → Secrets and variables → Actions

# Verify all 8 secrets are present:
# 1. AWS_ACCESS_KEY_ID
# 2. AWS_SECRET_ACCESS_KEY
# 3. AWS_ACCOUNT_ID
# 4. AWS_REGION
# 5. ECR_REPOSITORY
# 6. EC2_HOST
# 7. EC2_USER
# 8. EC2_SSH_KEY

# To test locally:
cat .env.example  # See what variables are expected
```

#### Error: "SSH connection timed out"

**Symptom**: GitHub Actions workflow fails at SSH deployment step:
```
timeout: handshake failed: Timeout waiting for SSH connection
```

**Cause**: 
- EC2 instance is not reachable
- Security group doesn't allow SSH (port 22)
- EC2 doesn't have public IP
- EC2_HOST secret is wrong

**Solution**:
```bash
# 1. Verify EC2 is running
aws ec2 describe-instances --instance-ids i-xxx \
  --query 'Reservations[0].Instances[*].[State.Name,PublicIpAddress]'

# 2. Check security group allows port 22
aws ec2 describe-security-groups --group-ids sg-xxx \
  --query 'SecurityGroups[0].IpPermissions[].[FromPort,ToPort,IpProtocol,IpRanges[0].CidrIp]'

# 3. Verify EC2_HOST secret is correct
# (Should match the public IP from step 1)

# 4. Test SSH manually
ssh -i my-ssh-key.pem ec2-user@<EC2_PUBLIC_IP> echo "SSH works"

# 5. If SSH works locally but not in Actions, check:
# - EC2_SSH_KEY secret contains entire private key (with newlines)
# - Use: cat my-ssh-key.pem to copy full content
```

#### Error: "Docker image not found in ECR"

**Symptom**: Deployment step fails:
```
Error response from daemon: pull access denied for xxx.dkr.ecr.us-east-1.amazonaws.com/nextjs-app-repo
```

**Cause**: 
- Image tag mismatch
- ECR repository doesn't exist
- AWS credentials don't have ECR access

**Solution**:
```bash
# 1. Verify ECR repository exists
aws ecr describe-repositories --repository-names nextjs-app-repo

# 2. Verify image was pushed
aws ecr describe-images --repository-name nextjs-app-repo

# 3. Check AWS credentials have ECR access
aws iam get-user-policy  # May not show; check IAM console

# 4. Fix in GitHub Actions workflow if needed:
# The IMAGE_TAG should be ${{ github.sha }}
# Or use 'latest' as fallback
```

#### Error: "AccessDenied: User is not authorized to perform: ecr:GetAuthorizationToken"

**Symptom**: AWS credentials don't have ECR permissions

**Cause**: IAM policy is missing ECR access

**Solution**:
```bash
# Verify IAM user has this policy
aws iam list-attached-user-policies --user-name your-user

# Should include:
# - AmazonEC2ContainerRegistryPowerUser or AmazonEC2ContainerRegistryFullAccess

# Attach if missing
aws iam attach-user-policy \
  --user-name your-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

---

### Docker & Container Issues

#### Error: "Unable to locate image 'nextjs-local:latest'"

**Symptom**: `docker run` fails to find image

**Cause**: Image wasn't built

**Solution**:
```bash
# Build the image first
docker build -t nextjs-local .

# Verify image exists
docker images | grep nextjs-local

# Then run
docker run -p 3000:3000 nextjs-local
```

#### Error: "Error response from daemon: driver failed programming external connectivity"

**Symptom**: `docker run -p 3000:3000` fails with port error

**Cause**: 
- Port 3000 already in use
- Docker daemon issue

**Solution**:
```bash
# Check what's using port 3000
lsof -i :3000          # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill the process (if safe)
kill -9 <PID>          # macOS/Linux

# Or use a different port
docker run -p 3001:3000 nextjs-local

# Restart Docker daemon
docker restart
```

#### Error: "standard_init_linux.go:228: exec user process caused: no such file or directory"

**Symptom**: Container starts but immediately exits

**Cause**: 
- Node.js not found in path
- Entrypoint/CMD is wrong

**Solution**:
```bash
# Check Dockerfile CMD
cat Dockerfile | grep -A5 "CMD\|ENTRYPOINT"

# Should be:
# CMD ["npm", "start"]

# Verify in image
docker inspect nextjs-local | grep -A5 "Cmd"

# Rebuild if needed
docker build --no-cache -t nextjs-local .
```

#### Container runs but port 3000 not accessible

**Symptom**: Cannot connect to http://localhost:3000

**Cause**: 
- Port mapping not set correctly
- Next.js not binding to 0.0.0.0
- Firewall blocking

**Solution**:
```bash
# Check port mapping
docker port nextjs-app

# Should show: 3000/tcp -> 0.0.0.0:3000

# Check if container is running
docker ps

# Check logs
docker logs nextjs-app

# Enter container and debug
docker exec -it nextjs-app sh
# Inside:
netstat -tlnp | grep 3000
curl http://localhost:3000
```

---

### EC2 Instance Issues

#### Error: "SSH: Permission denied (publickey)"

**Symptom**: SSH connection rejected with permission denied

**Cause**: 
- Wrong SSH key used
- EC2 user is wrong
- Key permissions are wrong

**Solution**:
```bash
# Verify key permissions
ls -la my-ssh-key.pem
# Should show: -r--------  (400 permissions)

chmod 400 my-ssh-key.pem

# Verify correct EC2 user
# Amazon Linux 2 uses: ec2-user
# Ubuntu uses: ubuntu
ssh -i my-ssh-key.pem ubuntu@<IP>  # Try both

# Verify correct key pair
aws ec2 describe-key-pairs --region us-east-1

# Test SSH connection
ssh -v -i my-ssh-key.pem ec2-user@<IP>  # -v for verbose
```

#### Container isn't running on EC2

**Symptom**: Navigate to EC2 IP but get connection refused

**Cause**: 
- Container didn't start
- Docker daemon crashed
- Wrong image pulled

**Solution**:
```bash
# SSH into EC2
ssh -i my-ssh-key.pem ec2-user@<IP>

# Check Docker status
sudo systemctl status docker
sudo systemctl start docker  # If stopped

# List all containers (including stopped)
docker ps -a

# Check logs
docker logs nextjs-app

# If stopped, restart
docker restart nextjs-app

# Check processes
docker top nextjs-app

# Remove and restart if necessary
docker stop nextjs-app
docker rm nextjs-app
docker run -d --name nextjs-app --restart unless-stopped -p 80:3000 <IMAGE_URL>:latest

# Verify
docker ps
curl http://localhost:3000
```

#### Error: "No space left on device"

**Symptom**: EC2 instance runs out of disk space

**Cause**: 
- Old Docker images fill up disk
- Application logs too large
- Node modules cached

**Solution**:
```bash
# SSH into EC2
ssh -i my-ssh-key.pem ec2-user@<IP>

# Check disk usage
df -h

# Clean Docker
docker system prune -a  # Remove all unused images/containers
docker volume prune     # Remove unused volumes

# Check logs
du -sh /var/log/*
sudo rm -rf /var/log/*.log

# Check application logs
docker logs nextjs-app | wc -l  # Count log lines

# Restart to clear
docker restart nextjs-app
```

---

### AWS & Billing Issues

#### Error: "You have exceeded your on-demand instance limit"

**Symptom**: Cannot create EC2 instance, insufficient capacity

**Cause**: AWS Free Tier or account limits reached

**Solution**:
```bash
# Check current instance count
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceType,State.Name]' --output table

# Check limits
aws service-quotas list-service-quotas --service-code ec2 \
  --query 'ServiceQuotas[?QuotaName==`Running On-Demand t2 instances`]' \
  --output table

# Request limit increase (AWS console → Service Quotas)

# Or destroy old instances
terraform destroy
```

#### Large AWS Bill

**Symptom**: Unexpected AWS charges

**Cause**: 
- EC2 running 24/7
- Old snapshots not deleted
- Data transfer costs
- Multiple instances created

**Solution**:
```bash
# Stop EC2 when not in use
aws ec2 stop-instances --instance-ids i-xxx

# Delete old ECR images
aws ecr describe-images --repository-name nextjs-app-repo \
  --query 'imageDetails[*].[imageId,imagePushedAt]' --output table

# Delete old images
aws ecr batch-delete-image \
  --repository-name nextjs-app-repo \
  --image-ids imageTag=old-tag

# Set up AWS Budgets for alerts
aws budgets create-budget --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget BudgetName=MyBudget,BudgetLimit='Amount=50,Unit=USD'

# Or destroy everything if no longer needed
terraform destroy
```

---

### Testing Solutions

#### Test Terraform Configuration Locally

```bash
cd infra

# Validate syntax
terraform validate

# Format check
terraform fmt -check -recursive

# Lint with TFLint (if installed)
tflint

# Dry-run (plan only, don't apply)
terraform plan -out plan.tfplan
```

#### Test Docker Build Locally

```bash
# Build image
docker build -t nextjs-local .

# Run container
docker run --rm -it -p 3000:3000 nextjs-local

# Enter container to debug
docker run --rm -it -p 3000:3000 --entrypoint /bin/sh nextjs-local

# Inside container:
ls -la /app
npm list
ps aux
```

#### Test GitHub Actions Locally

Install [act](https://github.com/nektos/act):
```bash
# macOS
brew install act

# Run workflow locally
act -j build-and-push -s AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -s AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY ...
```

---

### Getting Help

1. **Check logs**:
   - Terraform: `terraform apply -verbose`
   - GitHub Actions: Workflow run → Step logs
   - EC2: `docker logs nextjs-app`
   - AWS: CloudTrail, CloudWatch

2. **Search errors**:
   - Google the error message
   - Check AWS documentation
   - Review GitHub Issues

3. **Ask for help**:
   - GitHub Discussions (if repo has it)
   - Stack Overflow (tag: `terraform`, `aws`, `github-actions`)
   - AWS Support (if paid plan)

---

Next: [Security Guide](./security.md) for protecting your deployment
