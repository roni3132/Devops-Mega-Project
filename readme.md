Create 1 Master machine on AWS with 2CPU, 8GB of RAM (t2.large) and 29 GB of storage and install Docker on it.


sudo apt-get update
sudo apt-get install docker.io -y
sudo usermod -aG docker ubuntu && newgrp docker


Install and configure Jenkins (Master machine)

sudo apt get update
sudo apt install fontconfig openjdk-17-jre -y

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
  
sudo apt-get update 
sudo apt-get install jenkins


Install kubectl (Master machine)(Setup kubectl )
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --short --client


Install eksctl (Master machine) (Setup eksctl)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version


Create EKS Cluster (Master machine)
eksctl create cluster --name=wanderlust \
                    --region=us-east-2 \
                    --version=1.30 \
                    --without-nodegroup

Associate IAM OIDC Provider (Master machine)
eksctl utils associate-iam-oidc-provider \
  --region us-east-2 \
  --cluster wanderlust \
  --approve


Create Nodegroup (Master machine)

ssh-keygen -t rsa -b 2048 -f ~/.ssh/eks-nodegroup-key
aws ec2 import-key-pair --key-name eks-nodegroup-key --public-key-material file://~/.ssh/eks-nodegroup-key.pub --region us-east-2

OR
aws ec2 create-key-pair \
  --key-name eks-nodegroup-key \
  --query 'KeyMaterial' \
  --output text \
  --region us-east-2 > eks-nodegroup-key.pem

chmod 400 eks-nodegroup-key.pem



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



this will take too much time approx 20+ min till that time we can confige our Jenkins 

open the port no 8080 in securtiy groups and hit the http://your_id:8080


see password of jenkins 
$ sudo cat /var/lib/jenkins/secrets/initialAdminPassword


you will see password and use them to login jenkins and select recomended plugins 

however it install we should install Trivy 

sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install trivy -y

docker run -itd --name SonarQube-Server -p 9000:9000 sonarqube:lts-community

Install and Configure ArgoCD (Master Machine)

Create argocd namespace


kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
watch kubectl get pods -n argocd
sudo curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.7/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd
kubectl get svc -n argocd
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl get svc -n argocd

open port for argocd 

get password for login argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo


Steps to implement the project:
Go to Jenkins Master and click on Manage Jenkins --> Plugins --> Available plugins install the below plugins:
OWASP
SonarQube Scanner
Docker
Pipeline: Stage View

Login to SonarQube server and create the credentials for jenkins to integrate with SonarQube
Navigate to Administration --> Security --> Users --> Token

Now, go to Manage Jenkins --> credentials and add Sonarqube credentials
Go to Manage Jenkins --> Tools and search for SonarQube Scanner installations:
Go to Manage Jenkins --> credentials and add Github credentials to push updated code from the pipeline:
While adding github credentials add Personal Access Token in the password field.
(GitHub settings, then Developer settings, and select "Personal access tokens" to generate a new token,)




