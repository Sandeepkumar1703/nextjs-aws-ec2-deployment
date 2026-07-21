#!/usr/bin/env bash
set -euo pipefail

# Install Docker and AWS CLI on Amazon Linux 2 / Ubuntu
if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

if [[ "$ID" == "amzn" || "$ID_LIKE" == *"rhel"* ]]; then
  # Amazon Linux 2
  sudo yum update -y
  sudo amazon-linux-extras install docker -y || true
  sudo yum install -y docker
  sudo service docker start || sudo systemctl start docker
  sudo usermod -a -G docker ec2-user || true
else
  # Debian/Ubuntu
  sudo apt-get update -y
  sudo apt-get install -y docker.io curl
  sudo systemctl enable --now docker
  sudo usermod -a -G docker $USER || true
fi

# Install AWS CLI v2 if missing
if ! command -v aws >/dev/null 2>&1; then
  TMPDIR=$(mktemp -d)
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TMPDIR/awscliv2.zip"
  unzip "$TMPDIR/awscliv2.zip" -d "$TMPDIR"
  sudo "$TMPDIR/aws/install" -i /usr/local/aws -b /usr/local/bin || true
  rm -rf "$TMPDIR"
fi

echo "Docker and AWS CLI installed"
