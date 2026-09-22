#!/bin/bash
set -e

sudo apt-get update -y
sudo apt-get install -y curl unzip apt-transport-https ca-certificates gnupg lsb-release wget

# 1. Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# 2. Install Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu

# 3. Run SonarQube Container
sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community

# 4. Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

# 5. Install Java & Maven
sudo apt-get install -y openjdk-17-jdk maven

# 6. Install Kubernetes CLI (kubectl)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# 7. Install Helm CLI
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 8. Configure Kubeconfig for local management
aws eks update-kubeconfig --region us-east-1 --name project-eks-cluster || true
sudo mkdir -p /root/.kube
if [ -f ~/.kube/config ]; then
  sudo cp ~/.kube/config /root/.kube/config
  sudo chown root:root /root/.kube/config
fi