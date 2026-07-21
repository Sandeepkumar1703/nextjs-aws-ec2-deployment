#!/bin/bash
set -e

# Log output for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

# Update and install Docker
if grep -q "amzn" /etc/os-release; then
  # Amazon Linux 2
  yum update -y
  amazon-linux-extras install docker -y || yum install -y docker
  systemctl enable --now docker
  usermod -a -G docker ec2-user || true
else
  # Debian/Ubuntu
  apt-get update -y
  apt-get install -y docker.io curl
  systemctl enable --now docker
  usermod -a -G docker ubuntu || true
fi

# Install AWS CLI v2 if not already present
if ! command -v aws &> /dev/null; then
  TMPDIR=$(mktemp -d)
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$${TMPDIR}/awscliv2.zip"
  unzip -q "$${TMPDIR}/awscliv2.zip" -d "$${TMPDIR}"
  "$${TMPDIR}/aws/install" -i /usr/local/aws -b /usr/local/bin || true
  rm -rf "$${TMPDIR}"
fi

# Allow some time for docker daemon to start
sleep 5

# Authenticate with ECR
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin $${account_id}.dkr.ecr.${region}.amazonaws.com || true

# Pull and run the Docker image
IMAGE="${ecr_repo}:${image_tag}"

# Attempt to pull the image with retries
MAX_RETRIES=3
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if docker pull $${IMAGE}; then
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  sleep 10
done

# Stop existing container if running
docker rm -f nextjs-app || true

# Run the container
docker run -d \
  --name nextjs-app \
  --restart unless-stopped \
  -p 80:3000 \
  $${IMAGE}

echo "Docker image deployed successfully at $(date)"

