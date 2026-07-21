# Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Developer Workflow                           │
│                                                                     │
│  1. Push code to GitHub main branch                                │
│  2. GitHub Actions CI/CD pipeline triggers automatically           │
└────────────┬────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                 GitHub Actions CI/CD Pipeline                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Step 1: Checkout code from repository                       │  │
│  │ Step 2: Configure AWS credentials (from GitHub Secrets)     │  │
│  │ Step 3: Login to Amazon ECR                                 │  │
│  │ Step 4: Build Docker image (multi-stage)                    │  │
│  │ Step 5: Tag image with commit SHA                           │  │
│  │ Step 6: Push image to Amazon ECR                            │  │
│  │ Step 7: SSH into EC2 instance                               │  │
│  │ Step 8: Pull latest image from ECR                          │  │
│  │ Step 9: Stop old container (if running)                     │  │
│  │ Step 10: Run new container on EC2                           │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────┬──────────────────────────┬──────────────────────────────┘
             │                          │
             ▼                          ▼
     ┌──────────────┐           ┌───────────────────┐
     │ Amazon ECR   │           │ AWS EC2 Instance  │
     ├──────────────┤           ├───────────────────┤
     │ - Private    │           │ - t2.micro (Free) │
     │   repo for   │──Pull──→  │ - Amazon Linux 2  │
     │   Docker     │  Image    │ - IAM role        │
     │   images     │           │ - Security group  │
     │ - Image      │           │ - VPC (10.0.0.0)  │
     │   scanning   │           │ - Public IP       │
     │ - Versioned  │           └────────┬──────────┘
     │   by SHA     │                    │
     └──────────────┘                    ▼
                              ┌───────────────────┐
                              │ Docker Container  │
                              ├───────────────────┤
                              │ Non-root user     │
                              │ Port: 3000        │
                              │ Restart policy:   │
                              │ unless-stopped    │
                              └────────┬──────────┘
                                       │
                                       ▼
                              ┌───────────────────┐
                              │  Next.js App      │
                              ├───────────────────┤
                              │ - React 18        │
                              │ - TypeScript      │
                              │ - SSR/SSG pages   │
                              │ - API routes      │
                              │ - Exposed on      │
                              │   Port 80 (EC2)   │
                              └───────────────────┘
```

## Infrastructure Components

### 1. **GitHub Repository**
- Source code management
- Triggers CI/CD pipeline on push to `main`
- Stores secrets (AWS keys, SSH keys)

### 2. **GitHub Actions**
- Automated build system
- Runs on Ubuntu runners (GitHub-hosted)
- Steps: checkout → build → push → deploy

### 3. **Amazon ECR (Elastic Container Registry)**
- Private Docker image repository
- Image scanning enabled (detects vulnerabilities)
- Images tagged by commit SHA for traceability
- Lifecycle policies can auto-delete old images

### 4. **AWS EC2 - Networking (Terraform Network Module)**
- **VPC** (10.0.0.0/16) - Isolated cloud network
- **Public Subnet** (10.0.1.0/24) - Internet-accessible
- **Internet Gateway** - Routes traffic to/from internet
- **Route Table** - Directs traffic to IGW (0.0.0.0/0)
- **Security Group** - Firewall rules
  - Inbound: Port 80 (HTTP) from 0.0.0.0/0
  - Inbound: Port 22 (SSH) from 0.0.0.0/0
  - Outbound: Allow all traffic

### 5. **AWS EC2 - Compute (Terraform EC2 Module)**
- **Instance Type**: t2.micro (Free Tier eligible)
- **OS**: Amazon Linux 2 (free, optimized for AWS)
- **AMI**: Latest Amazon Linux 2 (auto-detected via data source)
- **IAM Role**: EC2ContainerRegistryReadOnly permission
  - Allows pulling images from ECR without SSH keys
- **User Data Script**: Runs on first boot
  - Installs Docker
  - Installs AWS CLI v2
  - Authenticates to ECR
  - Pulls Docker image
  - Runs container with restart policy

### 6. **Docker Container**
- **Base**: node:18-alpine
- **User**: nextjs:nodejs (UID 1001, non-root)
- **Port**: 3000 (mapped to EC2 port 80 via `-p 80:3000`)
- **Restart Policy**: unless-stopped (survives EC2 reboots)
- **Volume**: None (stateless app)

### 7. **Next.js Application**
- **Framework**: Next.js 14+ (latest)
- **Language**: TypeScript
- **Features**: SSR, SSG, API routes, Image optimization
- **Build**: Multi-stage Docker build
  - Stage 1: Builder (installs deps, builds app)
  - Stage 2: Runner (only production files, ~150MB)

## Data Flow

```
1. Developer pushes code to GitHub main
                    ↓
2. GitHub detects push event
                    ↓
3. GitHub Actions workflow starts
                    ↓
4. Checkout code, Setup Node.js
                    ↓
5. Install dependencies, Build Next.js
                    ↓
6. Build Docker image (multi-stage)
                    ↓
7. Authenticate to ECR with AWS credentials
                    ↓
8. Push image to ECR (tagged with commit SHA)
                    ↓
9. SSH into EC2 instance with GitHub secret key
                    ↓
10. Pull new image from ECR (EC2 IAM role auth)
                    ↓
11. Stop old container
                    ↓
12. Run new container with restart policy
                    ↓
13. Application available at EC2 public IP
```

## Security Architecture

### Network Security
- **VPC Isolation**: Application in private managed network
- **Security Groups**: Firewall restricts inbound/outbound traffic
- **No Direct Database Access**: No RDS in this setup

### Identity & Access
- **IAM Roles**: EC2 uses role-based permissions (not SSH keys)
- **GitHub Secrets**: AWS credentials encrypted by GitHub
- **SSH Key Auth**: GitHub Actions uses SSH key for EC2 access
- **Read-Only ECR**: EC2 can only pull, not push images

### Container Security
- **Non-root User**: Container runs as `nextjs:nodejs`, not root
- **Multi-stage Build**: Excludes build dependencies (dev tools, npm, etc.)
- **Alpine Linux**: Minimal base image reduces attack surface
- **No Secrets in Image**: All secrets from GitHub Secrets or environment variables

### Secrets Management (Never Committed)
- `.env` files excluded by `.gitignore`
- `terraform.tfvars` excluded by `.gitignore`
- SSH keys (`.pem`) excluded by `.gitignore`
- `terraform.tfstate` excluded (kept locally or in remote backend)

## Cost Architecture (Free Tier)

### Free Components
- **EC2**: t2.micro (750 hours/month)
- **ECR**: First 500 GB-month free
- **Data Transfer**: 1GB/month free egress
- **GitHub Actions**: 2,000 minutes/month free

### Paid Components (if exceeding free tier)
- **ECR Storage**: $0.50 per GB-month
- **Data Transfer**: $0.02 per GB (outbound only)
- **EC2**: $0.01-0.10/hour after free tier

### Cost Optimization Tips
1. Delete old Docker images from ECR
2. Set ECR lifecycle policies
3. Stop EC2 when not in use
4. Use AWS Budgets for alerts
5. Monitor CloudWatch metrics

## Deployment Topology

```
┌─────────────────────────────────────────────┐
│            AWS Region: us-east-1             │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │       VPC: 10.0.0.0/16                │  │
│  │                                       │  │
│  │  ┌────────────────────────────────┐   │  │
│  │  │  Public Subnet: 10.0.1.0/24    │   │  │
│  │  │                                │   │  │
│  │  │  ┌──────────────────────────┐  │   │  │
│  │  │  │   EC2 Instance           │  │   │  │
│  │  │  │   - IP: 10.0.1.X         │  │   │  │
│  │  │  │   - Public IP: auto      │  │   │  │
│  │  │  │                          │  │   │  │
│  │  │  │  ┌──────────────────┐    │  │   │  │
│  │  │  │  │ Docker Container │    │  │   │  │
│  │  │  │  │ Port 3000        │    │  │   │  │
│  │  │  │  └──────────────────┘    │  │   │  │
│  │  │  │                          │  │   │  │
│  │  │  │ Security Group: Allow    │  │   │  │
│  │  │  │ - Port 80 (HTTP)         │  │   │  │
│  │  │  │ - Port 22 (SSH)          │  │   │  │
│  │  │  └──────────────────────────┘  │   │  │
│  │  │                                │   │  │
│  │  └────────────────────────────────┘   │  │
│  │           ↑                           │  │
│  │      Internet Gateway                │  │
│  │           ↓                           │  │
│  │   Route Table: 0.0.0.0/0 → IGW      │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │   Amazon ECR Repository               │  │
│  │   - nextjs-app-repo:latest            │  │
│  │   - nextjs-app-repo:<commit-sha>      │  │
│  │   - Image scanning enabled            │  │
│  └───────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
         ↑
         │ HTTP/HTTPS
         │
    Internet Users
```

## Alternative Architectures

### Production Upgrade (Not Included)
```
Load Balancer (ALB)
       ↓
   ┌───┴────┐
   ↓        ↓
  EC2-1    EC2-2
 (Docker) (Docker)
   ↓        ↓
   └───┬────┘
       ↓
   RDS (PostgreSQL)
```

### Kubernetes Alternative (Not Used)
- EKS (Elastic Kubernetes Service)
- More complex, not Free Tier
- Better for multi-container, auto-scaling needs

---

This architecture prioritizes **simplicity**, **security**, and **cost-efficiency** for small to medium projects.
