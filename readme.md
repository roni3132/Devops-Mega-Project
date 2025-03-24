# Wanderlust CI/CD Pipeline on AWS EKS Cluster

![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)
![Jenkins](https://img.shields.io/badge/Jenkins-CI/CD-blue)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-blueviolet)

A complete CI/CD pipeline implementation using Jenkins, ArgoCD, SonarQube, Trivy, and AWS EKS with monitoring via Prometheus/Grafana.

## 📋 Prerequisites
- AWS Account with IAM permissions
- SSH Key Pair
- Basic Docker/Kubernetes knowledge
- GitHub account with repository access

## 🖥️ Master Machine Setup
Create EC2 instance (t2.large) with:
- 2 vCPUs
- 8GB RAM
- 30GB Storage

```bash
sudo apt-get update
sudo apt-get install docker.io -y
sudo usermod -aG docker ubuntu && newgrp docker
```
##🛠️ Jenkins Setup
```bash

sudo apt update
sudo apt install fontconfig openjdk-17-jre -y
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update 
sudo apt-get install jenkins
```
Access Jenkins at http://<PUBLIC_IP>:8080 (open port 8080 in Security Group)

## ☸️ Kubernetes Tools Installation

```bash
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
```
## eksctl
```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```
## 🚀 EKS Cluster Creation

```bash
eksctl create cluster --name=wanderlust \
  --region=us-east-2 \
  --version=1.30 \
  --without-nodegroup

eksctl utils associate-iam-oidc-provider \
  --region us-east-2 \
  --cluster wanderlust \
  --approve

ssh-keygen -t rsa -b 2048 -f ~/.ssh/eks-nodegroup-key
aws ec2 import-key-pair --key-name eks-nodegroup-key --public-key-material file://~/.ssh/eks-nodegroup-key.pub --region us-east-2

eksctl create nodegroup --cluster=wanderlust \
  --region=us-east-2 \
  --name=wanderlust \
  --node-type=t2.medium \
  --nodes=2 \
  --nodes-min=2 \
  --nodes-max=2 \
  --node-volume-size=29 \
  --ssh-access \
  --ssh-public-key=eks-nodegroup-key
```
## 🔒 Security Tools
Trivy Installation
```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install trivy -y
```
## SonarQube Setup
```bash
docker run -itd --name SonarQube-Server -p 9000:9000 sonarqube:lts-community
```
##  🚢 ArgoCD Installation
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.7/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```
Get ArgoCD password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
## 📊 Monitoring Stack
Helm Installation

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
Prometheus/Grafana


```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
kubectl create namespace prometheus
helm install stable prometheus-community/kube-prometheus-stack -n prometheus
```
## 🛠️ Jenkins Configuration
1. Install required plugins:
  - OWASP
  - SonarQube Scanner
  - Docker Pipeline
2. Configure credentials for:
  - GitHub Personal Access Token
  - Docker Hub
  - SonarQube Token
3. Create pipelines:
  - Wanderlust-CI (Continuous Integration)
  - Wanderlust-CD (Continuous Deployment)

## 🎉 Final Steps
1. Configure ArgoCD to connect to your GitHub repo
2. Set up application in ArgoCD UI
3. Verify deployment on EKS
4. Access Grafana dashboard for monitoring

Congratulations! Your CI/CD pipeline is now fully operational on AWS EKS 🎉

Note: Allow 20-30 minutes for EKS cluster creation. Ensure all required ports (8080, 9000, 3000) are open in Security Groups.




