# Security Guide

## Overview

This document outlines the security measures implemented in this project and recommendations for production deployments.

## Security by Layer

### 1. Application Layer

#### Container Security

✅ **Non-root User** (Implemented)
```dockerfile
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
USER nextjs
```
- **Why**: Running as root allows attackers to compromise the entire system
- **Impact**: Even if container is breached, damage is limited to the app

✅ **Multi-stage Docker Build** (Implemented)
```dockerfile
FROM node:18-alpine AS builder
# Install deps, build app...

FROM node:18-alpine AS runner
# Copy only production files
```
- **Why**: Final image excludes dev dependencies, build tools, npm cache
- **Impact**: Smaller image (~150MB) = fewer attack vectors

✅ **Alpine Linux Base** (Implemented)
```dockerfile
FROM node:18-alpine
```
- **Why**: Alpine is 95% smaller than standard Node.js images
- **Impact**: Reduced vulnerability surface

✅ **Minimal Dependencies**
```json
{
  "dependencies": {
    "next": "latest",
    "react": "latest",
    "react-dom": "latest"
  }
}
```
- **Why**: Each dependency is a potential vulnerability
- **Recommendations**:
  - Use `npm audit` regularly
  - Keep dependencies updated
  - Use Dependabot (GitHub feature) for auto-updates

### 2. Network Layer

#### VPC Isolation

✅ **Private VPC** (Implemented)
- Application runs in 10.0.0.0/16 VPC (private IP range)
- Not directly exposed to internet
- Traffic filtered through security groups

#### Security Group Rules

✅ **Restrictive Ingress** (Implemented)
```hcl
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # HTTP from anywhere
}

ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # SSH from anywhere
}
```

**⚠️ Production Recommendation:**
```hcl
# Restrict SSH to specific IPs
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_OFFICE_IP/32"]  # Only your office
}

# Or use AWS Systems Manager Session Manager (no SSH needed)
```

✅ **Unrestricted Egress** (Implemented)
```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```
- **Why**: EC2 needs outbound access to pull Docker images from ECR
- **Recommendation**: In production, restrict to ECR endpoints only

### 3. Identity & Access Layer

#### IAM Role-Based Access

✅ **EC2 IAM Role** (Implemented)
```hcl
resource "aws_iam_role" "ec2_role" {
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

- **Why**: EC2 can authenticate to ECR without storing AWS keys on the instance
- **Benefit**: If EC2 is compromised, attacker cannot access other AWS resources
- **Permission**: Read-only access to ECR (cannot delete or modify images)

✅ **No Hardcoded Credentials** (Implemented)
- ❌ NEVER store `AWS_ACCESS_KEY_ID` on EC2
- ❌ NEVER store `AWS_SECRET_ACCESS_KEY` in code
- ✅ Use IAM roles for AWS API access
- ✅ GitHub Secrets for CI/CD credentials

#### GitHub Secrets

✅ **Encrypted Secrets** (Implemented)
All sensitive data stored in GitHub Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`
- `EC2_SSH_KEY` (private key)

**How GitHub encrypts secrets:**
1. GitHub generates a public key for your repo
2. Secrets are encrypted with this key
3. Only GitHub Actions runners can decrypt with private key
4. Secrets are masked in logs (replaced with `***`)

**⚠️ Important**: Even with encryption, anyone with push access can read secrets via workflow logs. Best practice: Use OIDC federation (see below).

#### AWS OIDC Federation (Recommended)

⏳ **Not Implemented** (Optional Enhancement)

Instead of storing long-lived AWS credentials:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::ACCOUNT:role/GitHubActionsRole
    aws-region: us-east-1
```

**Benefits:**
- No access key ID or secret key stored
- Credentials are temporary (1 hour max)
- Credentials auto-rotate
- Better audit trail in CloudTrail

### 4. Data Layer

#### Secrets Not in Version Control

✅ **`.gitignore` Protects** (Implemented)
```
.env
terraform.tfvars
*.pem
*.key
.terraform/
terraform.tfstate
```

**Verification:**
```bash
# Check that no secrets are committed
git log -p --all -- "*.pem" | head -5
git log -p --all -- "terraform.tfvars" | head -5
git log -p --all -- ".env" | head -5
```

If secrets are accidentally committed:
1. Use `git-secret` or `BFG Repo-Cleaner` to remove from history
2. Rotate all compromised credentials immediately
3. Force-push if necessary

### 5. CI/CD Layer

#### GitHub Actions Security

✅ **Read-Only Checkout** (Implemented)
```yaml
- name: Checkout
  uses: actions/checkout@v4
```
- No modifications to source code
- Verifies branch is clean before deploy

✅ **Explicit Secrets Usage** (Implemented)
```yaml
- name: Configure AWS credentials
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```
- Secrets only used where needed
- Not accidentally logged or stored

✅ **SSH-Based Deployment** (Implemented)
```yaml
- name: Deploy to EC2
  uses: appleboy/ssh-action@v0.1.7
  with:
    key: ${{ secrets.EC2_SSH_KEY }}
```
- Deployment via SSH (secure transport)
- Not via HTTP webhooks (exposed credentials)

#### ECR Image Scanning

✅ **Enabled** (Implemented)
```hcl
resource "aws_ecr_repository" "app" {
  image_scanning_configuration {
    scan_on_push = true
  }
}
```

- Every image pushed to ECR is scanned for vulnerabilities
- Results available in AWS console
- Can fail builds if critical vulnerabilities detected

**Recommendation**: Configure in CI/CD to reject images with HIGH/CRITICAL CVEs:
```bash
aws ecr describe-image-scan-findings \
  --repository-name nextjs-app-repo \
  --image-id imageTag=latest
```

### 6. Infrastructure as Code Security

#### Terraform Security

✅ **No Hardcoded Values** (Implemented)
```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "ssh_key_name" {
  default = ""  # User provides this
}
```

✅ **Dynamic Data Sources** (Implemented)
```hcl
data "aws_caller_identity" "current" {}  # Get account ID dynamically
data "aws_ami" "al2" { ... }             # Get latest AMI automatically
```

✅ **State File Protection** (Local Only)
```bash
# Default: terraform.tfstate stored locally
# Contains sensitive values (passwords, keys)
# MUST be protected
```

**Production Recommendation**: Use remote state with encryption:
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Security Checklist

### Before First Deployment

- [ ] `.env` never committed (only `.env.example`)
- [ ] `terraform.tfvars` never committed (only `.tfvars.example`)
- [ ] SSH keys (`.pem`) never committed
- [ ] AWS credentials not in code or README
- [ ] `.gitignore` protection verified: `git status --porcelain`
- [ ] GitHub repository set to private (if not open source)
- [ ] All 8 GitHub Secrets configured
- [ ] SSH key pair created and permissions set (chmod 400)

### Before Each Deployment

- [ ] Run `npm audit` and address HIGH/CRITICAL vulnerabilities
- [ ] Review `.env` values before deploying
- [ ] Verify GitHub Actions workflow log doesn't display secrets
- [ ] Check CloudTrail for unauthorized API calls
- [ ] Review security group rules in AWS console

### Production Deployment

- [ ] Enable CloudWatch monitoring and alarms
- [ ] Enable CloudTrail for audit logging
- [ ] Set up AWS Budgets for cost alerts
- [ ] Rotate SSH keys every 90 days
- [ ] Use VPC endpoints for private ECR access
- [ ] Implement WAF (Web Application Firewall) if available
- [ ] Enable GuardDuty for threat detection
- [ ] Set up Systems Manager Session Manager (optional SSH alternative)
- [ ] Implement auto-scaling for high-traffic scenarios
- [ ] Use AWS Secrets Manager for sensitive configuration

## Common Security Issues & Fixes

### ❌ Issue: Secrets Visible in Logs

```yaml
# Bad
- name: Deploy
  run: |
    export AWS_KEY=${{ secrets.AWS_KEY }}
    echo "Key is: $AWS_KEY"  # Exposed in logs!
```

```yaml
# Good
- name: Deploy
  env:
    AWS_KEY: ${{ secrets.AWS_KEY }}
  run: |
    deploy_script.sh  # Secret passed via environment only
```

### ❌ Issue: SSH Key Hardcoded in Repo

```bash
# Bad - NEVER do this
chmod 600 my-ssh-key.pem
git add my-ssh-key.pem
git commit -m "Add SSH key"

# Good
echo "*.pem" >> .gitignore
git rm --cached my-ssh-key.pem
```

### ❌ Issue: ECR Repository Is Public

```bash
# Check current policy
aws ecr describe-repositories --repository-names nextjs-app-repo

# Ensure visible only to AWS account
aws ecr set-repository-policy \
  --repository-name nextjs-app-repo \
  --policy-text '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::ACCOUNT:root"},"Action":"ecr:*"}]}'
```

### ❌ Issue: Overly Permissive Security Group

```bash
# Bad - allows SSH from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

# Good - restrict to your IP
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp --port 22 --cidr YOUR_IP/32
```

## Monitoring & Alerts

### CloudWatch Alarms

```bash
# Monitor failed login attempts
aws cloudwatch put-metric-alarm \
  --alarm-name EC2-High-Network-In \
  --alarm-description "Alert when EC2 network traffic is high" \
  --metric-name NetworkIn \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 1000000 \
  --comparison-operator GreaterThanThreshold
```

### CloudTrail Logging

```bash
# Enable CloudTrail for audit
aws cloudtrail create-trail --name my-trail --s3-bucket-name my-bucket
aws cloudtrail start-logging --trail-name my-trail

# List recent API calls
aws cloudtrail lookup-events --max-results 10
```

## Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [OWASP Top 10 Web Application Security Risks](https://owasp.org/www-project-top-ten/)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Terraform AWS Security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides)

---

**Remember**: Security is not a one-time event, it's an ongoing process. Stay informed about new vulnerabilities and keep your dependencies updated!
