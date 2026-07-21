# Next.js AWS EC2 Deployment using Docker & Amazon ECR

## Project Overview

This project demonstrates the deployment of a **Next.js TypeScript web application** on AWS using modern DevOps practices.

The application is containerized using **Docker**, stored in **Amazon Elastic Container Registry (ECR)**, and deployed on an **Amazon EC2 instance**.

The objective of this project was to understand and implement a real-world cloud deployment workflow:


Developer Laptop
|
|
Docker Build
|
|
▼
Docker Image
|
|
Docker Push
|
|
▼
Amazon ECR
Private Registry
|
|
Docker Pull
|
|
▼
Amazon EC2
|
|
Docker Run
|
|
▼
Next.js Application


---

# Architecture

                     GitHub Repository
                            |
                            |
                     Source Code
                            |
                            |
                     Developer Laptop
                            |
                            |
                     docker build
                            |
                            |
                     Docker Image
                            |
                            |
                     docker push
                            |
                            |
                     Amazon ECR
                     Private Registry
                            |
                            |
                     docker pull
                            |
                            |
                     Amazon EC2
                Amazon Linux 2023
                            |
                            |
                     docker run
                            |
                            |
                 Next.js Container
                            |
                            |
                   Port 3000
                            |
                            |
                     Web Browser

---

# Technologies Used

## Next.js

### Why Next.js?

Next.js was used as the frontend framework because it provides:

- React-based development
- Server-side rendering support
- Optimized production builds
- Better performance
- TypeScript support


---

## TypeScript

### Why TypeScript?

TypeScript improves:

- Code quality
- Maintainability
- Developer productivity
- Error detection during development


---

## Docker

### Why Docker?

Docker was used to package the application with all required dependencies.

Benefits:

- Consistent runtime environment
- Application portability
- Easy deployment
- Environment isolation


Docker workflow:


Application Code
|
|
Dockerfile
|
|
Docker Image
|
|
Docker Container


---

## Amazon ECR

### Why Amazon ECR?

Amazon Elastic Container Registry was used as a private Docker image repository.

Benefits:

- Secure Docker image storage
- AWS IAM integration
- Private container registry
- Easy integration with AWS services


---

## Amazon EC2

### Why EC2?

EC2 was selected to host the Docker container.

Benefits:

- Full server control
- Flexible configuration
- Suitable for learning production deployment
- Supports Docker workloads


EC2 Configuration:


Instance Type:
t2.micro

Operating System:
Amazon Linux 2023

Application Port:
3000


---

## AWS IAM

IAM was used to securely authenticate AWS CLI and access AWS services.

Created IAM user:


devops-group


Attached permissions:


AmazonEC2FullAccess

AmazonEC2ContainerRegistryFullAccess


---

# Deployment Workflow

## Step 1: Develop Application Locally

The Next.js application was developed and tested locally.

Install dependencies:

```bash
npm install

Run locally:

npm run dev

Application:

http://localhost:3000
Step 2: Create Docker Image

Build Docker image:

docker build -t nextjs-aws-app .

Verify image:

docker images

Example:

nextjs-aws-app:latest
Step 3: Configure AWS CLI

Install AWS CLI and configure credentials:

aws configure

Enter:

AWS Access Key ID

AWS Secret Access Key

Default region:
ap-south-1

Output:
json

Verify:

aws sts get-caller-identity

Expected output:

{
    "UserId": "xxxx",
    "Account": "xxxx",
    "Arn": "arn:aws:iam::xxxx:user/devops-group"
}
Step 4: Login to Amazon ECR

Authenticate Docker with AWS ECR:

aws ecr get-login-password \
--region ap-south-1 |
docker login \
--username AWS \
--password-stdin \
ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

Successful output:

Login Succeeded
Step 5: Tag Docker Image

Tag local image with ECR repository URL:

docker tag \
nextjs-aws-app:latest \
ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/nextjs-aws-app:latest
Step 6: Push Docker Image to ECR

Upload image:

docker push \
ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/nextjs-aws-app:latest

Example output:

latest: digest:
sha256:xxxx

Docker image is now available in ECR.

Step 7: Deploy Application on EC2

Connect to EC2:

ssh -i key.pem ec2-user@EC2_PUBLIC_IP

Install Docker:

sudo yum install docker -y

sudo systemctl start docker

sudo systemctl enable docker
Step 8: Authenticate EC2 with ECR

On EC2:

aws ecr get-login-password \
--region ap-south-1 |
docker login \
--username AWS \
--password-stdin \
ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com
Step 9: Pull Docker Image

Download image:

docker pull \
ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/nextjs-aws-app:latest
Step 10: Run Container

Start application:

docker run -d \
--name nextjs-app \
-p 3000:3000 \
ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/nextjs-aws-app:latest

Verify:

docker ps

Expected:

CONTAINER ID

IMAGE

PORTS

STATUS
Application Access

Application runs on:

http://EC2_PUBLIC_IP:3000

Example:

http://13.xxx.xxx.xxx:3000
Docker Commands Used

Build image:

docker build -t nextjs-aws-app .

View images:

docker images

Run container:

docker run -d -p 3000:3000 image-name

Check containers:

docker ps

View logs:

docker logs nextjs-app

Stop container:

docker stop nextjs-app

Remove container:

docker rm nextjs-app
Security Considerations
IAM Security

Implemented:

AWS IAM authentication
Permission-based access
No AWS credentials stored in code
Docker Security

Implemented:

Containerized application
Isolated runtime environment
Production build process
EC2 Security Group

Required inbound ports:

SSH
22

Application
3000

Production recommendation:

Instead of:

0.0.0.0/0

Use:

Your IP/32

for SSH access.

Cost Optimization

This project uses AWS Free Tier eligible resources where possible.

Resources:

EC2 t2.micro

IAM

AWS CLI

Small ECR repository

To avoid unnecessary charges:

Stop EC2 when not required:

AWS Console:

EC2
 |
Instances
 |
Stop Instance

Remove unused ECR images:

aws ecr delete-repository \
--repository-name nextjs-aws-app \
--force
Troubleshooting
SSH Connection Timeout

Problem:

ssh: connect to host port 22 timeout

Possible reasons:

EC2 instance stopped
Security group missing port 22
Public IP changed

Solution:

Start EC2 and verify:

Inbound Rule

TCP 22

Your IP
Docker Image Not Found

Problem:

No such image

Solution:

Check local images:

docker images

Pull from ECR:

docker pull IMAGE_URI
Application Not Accessible

Check container:

docker ps

Check logs:

docker logs nextjs-app

Check port:

sudo ss -tulpn | grep 3000
Future Improvements

Planned improvements:

CI/CD Automation

Implement:

GitHub Push

      |

GitHub Actions

      |

Docker Build

      |

ECR Push

      |

EC2 Deployment
Infrastructure as Code

Automate AWS resources using:

Terraform
AWS CloudFormation
Production Enhancements

Add:

Application Load Balancer
HTTPS using AWS Certificate Manager
Custom Domain
CloudWatch Monitoring
Auto Scaling
ECS/EKS deployment
Project Status

Current implementation:

✅ Next.js application
✅ TypeScript
✅ Docker containerization
✅ Amazon ECR repository
✅ EC2 deployment
✅ AWS IAM authentication
✅ Manual deployment workflow

Future:

⬜ GitHub Actions CI/CD
⬜ Terraform automation
⬜ HTTPS deployment
⬜ Monitoring and alerting

Author

Sandeep Kumar Prasad

DevOps / Cloud Engineering Project


This README matches what you **actually performed**:
- Laptop → Docker build ✅
- Docker push → ECR ✅
- EC2 → Docker pull ✅
- EC2 → Docker run ✅
- Next.js running on port 3000 ✅

It avoids claiming things you haven't completed yet (full CI/CD, Terraform automation, ALB, HTTPS). This is safer for interviews and GitHub portfolio.