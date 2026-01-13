# EKS 2048 Game - Production-Grade Kubernetes Deployment

A complete cloud-native application deployment on Amazon EKS demonstrating production-ready infrastructure, automated CI/CD pipelines, GitOps workflows, and comprehensive monitoring.

## Overview

This project deploys a containerized 2048 game on AWS EKS with full automation. The infrastructure is managed as code using Terraform modules, applications deploy via GitOps with ArgoCD, and the entire stack includes monitoring, SSL certificates, and automated DNS management.

The application is accessible at: `https://game.eks.hamsa-ahmed.co.uk`

## Architecture

### Infrastructure Components

**AWS Resources:**
- EKS 1.31 cluster with managed node groups (t3.medium instances)
- VPC with public and private subnets across 2 availability zones
- NAT Gateway for private subnet internet access
- Route53 hosted zone for DNS management
- ECR repository for Docker images
- IAM roles with EKS Pod Identity for service accounts

**Kubernetes Add-ons:**
- AWS Load Balancer Controller (manages NLB for ingress)
- NGINX Ingress Controller (routes traffic to services)
- cert-manager (automated Let's Encrypt SSL certificates)
- ExternalDNS (syncs Kubernetes ingress to Route53)
- ArgoCD (GitOps continuous deployment)
- Prometheus (metrics collection)
- Grafana (metrics visualization)
- metrics-server (pod autoscaling support)

### Traffic Flow
```
User Request
    ↓
Route53 DNS (game.eks.hamsa-ahmed.co.uk)
    ↓
AWS Network Load Balancer
    ↓
NGINX Ingress Controller
    ↓
Kubernetes Service
    ↓
Application Pods (2048 game)
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform 1.12.2 or later
- kubectl
- A registered domain with Route53 access
- GitHub account for CI/CD

## Project Structure
```
.
├── app/                    # Application source code
│   ├── Dockerfile
│   └── (game files)
├── infra/                  # Infrastructure as code
│   ├── modules/
│   │   ├── vpc/           # VPC, subnets, NAT gateway
│   │   ├── eks/           # EKS cluster and node groups
│   │   ├── route53/       # DNS zone configuration
│   │   ├── helm/          # Kubernetes add-ons
│   │   └── github-oidc/   # GitHub Actions authentication
│   ├── kubernetes/        # Kubernetes manifests
│   ├── values/            # Helm chart values
│   ├── backend.tf         # S3 backend configuration
│   ├── main.tf            # Root module
│   └── terraform.tfvars   # Variable values
└── .github/workflows/     # CI/CD pipelines
    ├── terraform-ci.yml
    └── docker-deploy.yml
```

## Deployment Guide

### Initial Setup

1. Clone the repository:
```bash
git clone https://github.com/HamsaHAhmed7/EKS-Game-Project.git
cd EKS-Game-Project
```

2. Update variables in `infra/terraform.tfvars`:
```terraform
aws_region      = "eu-west-2"
project         = "eks-game"
environment     = "dev"
domain          = "your-domain.com"
parent_zone_id  = "Z07385433QNXDZZ6RBE0E"  # Your Route53 zone ID
github_org      = "your-github-username"
github_repo     = "EKS-Game-Project"
```

3. Initialize and deploy infrastructure:
```bash
cd infra
terraform init
terraform plan
terraform apply
```

4. Configure kubectl:
```bash
aws eks update-kubeconfig --name eks-game-eks-cluster --region eu-west-2
```

5. Apply Kubernetes manifests:
```bash
kubectl apply -f kubernetes/
```

6. Update Route53 NS delegation:
   - Get nameservers: `terraform output route53_zone_nameservers`
   - Update parent zone NS record for `eks.your-domain.com`

7. Wait for DNS propagation (5-15 minutes) and certificate issuance:
```bash
kubectl get certificate -n default -w
kubectl get certificate -n argocd -w
kubectl get certificate -n kube-monitoring -w
```

### Accessing Services

**Application:** https://game.eks.hamsa-ahmed.co.uk

**ArgoCD:**
- URL: https://argocd.eks.hamsa-ahmed.co.uk
- Username: `admin`
- Password: `kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d`

**Grafana:**
- URL: https://grafana.eks.hamsa-ahmed.co.uk
- Username: `admin`
- Password: `admin123`

## CI/CD Pipelines

### Pipeline 1: Terraform Validation

Runs on changes to `infra/**` directory.

**Steps:**
1. Terraform format check
2. Terraform init and validate
3. Checkov security scanning (57 checks passed, 10 failed with soft-fail)
4. Terraform plan
5. PR comment with validation results

This pipeline validates infrastructure changes but does not auto-apply. Infrastructure changes require manual approval and deployment.

### Pipeline 2: Docker Build and Deployment

Runs on changes to `app/**` directory.

**Steps:**
1. Build Docker image
2. Scan image with Trivy (vulnerability detection)
3. Push image to ECR with commit SHA as tag
4. Update Kubernetes manifest with new image tag
5. Commit manifest change to Git
6. ArgoCD automatically syncs and deploys

**Complete workflow:**
```
Code change → GitHub push → GitHub Actions → Docker build → Trivy scan → 
ECR push → Manifest update → Git commit → ArgoCD sync → Pods updated
```

## Monitoring

Prometheus collects metrics from:
- Kubernetes API server
- Cluster nodes (CPU, memory, disk)
- Application pods
- NGINX Ingress (request rates, response codes, latency)

Grafana dashboards available:
- Kubernetes Cluster Overview (ID: 15759)
- Kubernetes Monitoring (ID: 315)
- NGINX Ingress Controller (ID: 9614)
- Node Exporter (ID: 1860)

Access Grafana at `https://grafana.eks.hamsa-ahmed.co.uk` to view real-time metrics.

## Security Features

**Infrastructure Security:**
- Checkov scanning on Terraform code (IaC security validation)
- Private subnets for EKS worker nodes
- Security groups limiting access
- IAM roles with least privilege via EKS Pod Identity

**Container Security:**
- Trivy vulnerability scanning on Docker images
- Base image: nginx:alpine (minimal attack surface)
- No hardcoded secrets in code

**Network Security:**
- TLS 1.2+ encryption via cert-manager
- Let's Encrypt production certificates
- Network policies (can be enhanced)

**Authentication:**
- EKS uses IAM for cluster access
- GitHub Actions uses OIDC (no long-lived credentials)
- Service accounts use Pod Identity (no IAM keys)

## GitOps Workflow

ArgoCD watches the `infra/kubernetes/` directory and automatically syncs changes to the cluster.

**Deployment process:**
1. Developer pushes code change
2. CI/CD builds and pushes new Docker image
3. CI/CD updates `infra/kubernetes/app.yaml` with new image tag
4. ArgoCD detects Git change
5. ArgoCD syncs new manifest to cluster
6. Kubernetes performs rolling update
7. Old pods terminate, new pods start

This ensures Git is the single source of truth for cluster state.

## Scaling

**Horizontal Pod Autoscaler (HPA):**
```yaml
minReplicas: 2
maxReplicas: 10
targetCPUUtilizationPercentage: 70
```

The application automatically scales between 2-10 pods based on CPU usage. metrics-server provides resource metrics to the HPA controller.

## Teardown

To destroy the infrastructure:
```bash
cd infra
./tear-down.sh
```

The script:
1. Deletes LoadBalancer services
2. Waits for AWS cleanup
3. Removes DNS records
4. Runs terraform destroy

Note: Manual cleanup may be required if NLBs or ENIs don't detach cleanly.

## Common Issues

**Certificate stuck in pending:**
- Wait 15-20 minutes for DNS propagation after infrastructure changes
- Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
- Verify DNS: `dig game.eks.hamsa-ahmed.co.uk`

**ArgoCD showing OutOfSync:**
- Click "Sync" in ArgoCD UI to manually trigger
- Check for differences: `argocd app diff eks-game`

**Pods not pulling ECR image:**
- Verify Pod Identity association: `kubectl describe sa -n default`
- Check node IAM role has ECR permissions

**Terraform state lock:**
- Force unlock: `terraform force-unlock <lock-id>`
- Check DynamoDB table for stuck locks

## Technology Stack

- **Infrastructure:** Terraform, AWS (EKS, VPC, Route53, IAM)
- **Container:** Docker, Amazon ECR
- **Orchestration:** Kubernetes 1.31
- **GitOps:** ArgoCD
- **Ingress:** NGINX Ingress Controller, AWS Load Balancer Controller
- **Security:** cert-manager, Let's Encrypt, Trivy, Checkov
- **DNS:** ExternalDNS, Route53
- **Monitoring:** Prometheus, Grafana
- **CI/CD:** GitHub Actions

## Lessons Learned

**DNS propagation is real:** After recreating Route53 zones, always wait 15-20 minutes before troubleshooting certificate issues. cert-manager handles retries automatically.

**Terraform and Helm don't mix well in CI/CD:** Helm provider authentication in GitHub Actions is tricky. Better to deploy infrastructure via Terraform locally and use GitOps for application deployments.

**ExternalDNS saves time:** Automatic DNS record management eliminates manual Route53 updates. Perfect for dynamic environments.

**State locking matters:** Always use DynamoDB locking with S3 backend to prevent concurrent Terraform runs from corrupting state.

**GitOps reduces deployment errors:** Git as source of truth means deployments are auditable, reversible, and consistent.

## License

MIT License - see LICENSE file for details.

## Author

Hamsa Ahmedthis is very good but a little long im going to add a demo video of the working app and screen shots too, so maybe cut it down a bit also leave space for screen short eg insert screen shot here or demo or architauyre diagram plese20:09Thought processThe user wants a shorter README with placeholders for screenshots, demo video, and architecture diagram. Let me condense it while keeping the essential information and adding clear placeholders for visual content.README.md:
markdown# EKS 2048 Game - Production-Grade Kubernetes Deployment

A production-ready application deployment on Amazon EKS with automated CI/CD, GitOps workflows, and comprehensive monitoring.

**Live Application:** https://game.eks.hamsa-ahmed.co.uk

[INSERT DEMO VIDEO HERE]

## Project Overview

This project demonstrates a complete cloud-native deployment pipeline on AWS EKS. The infrastructure is fully automated with Terraform, applications deploy via GitOps with ArgoCD, and the stack includes monitoring, SSL certificates, and automated DNS management.

[INSERT ARCHITECTURE DIAGRAM HERE]

## Key Features

- Production-grade EKS cluster with Terraform modules
- Automated CI/CD pipelines (Terraform validation + Docker deployment)
- GitOps continuous deployment with ArgoCD
- Automatic SSL/TLS certificates with cert-manager
- Dynamic DNS management with ExternalDNS
- Monitoring with Prometheus and Grafana
- Security scanning (Checkov for IaC, Trivy for containers)

## Architecture Components

**AWS Infrastructure:**
- EKS 1.31 cluster with managed node groups
- VPC with public/private subnets across 2 AZs
- Route53 for DNS management
- ECR for Docker images
- IAM roles with EKS Pod Identity

**Kubernetes Add-ons:**
- NGINX Ingress Controller (traffic routing)
- AWS Load Balancer Controller (NLB management)
- cert-manager (Let's Encrypt SSL)
- ExternalDNS (Route53 sync)
- ArgoCD (GitOps deployments)
- Prometheus + Grafana (monitoring)

[INSERT INFRASTRUCTURE SCREENSHOT HERE]

## Project Structure
```
.
├── app/                    # Application source code
├── infra/                  # Infrastructure as code
│   ├── modules/           # Terraform modules (VPC, EKS, Route53, Helm)
│   ├── kubernetes/        # Kubernetes manifests
│   └── values/            # Helm chart configurations
└── .github/workflows/     # CI/CD pipelines
```

## Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform 1.12.2+
- kubectl
- Registered domain with Route53 access

### Deployment

1. **Clone and configure:**
```bash
git clone https://github.com/HamsaHAhmed7/EKS-Game-Project.git
cd EKS-Game-Project
```

2. **Update variables in `infra/terraform.tfvars`:**
```terraform
aws_region      = "eu-west-2"
domain          = "your-domain.com"
parent_zone_id  = "YOUR_ZONE_ID"
github_org      = "your-username"
github_repo     = "EKS-Game-Project"
```

3. **Deploy infrastructure:**
```bash
cd infra
terraform init
terraform apply
```

4. **Configure kubectl and apply manifests:**
```bash
aws eks update-kubeconfig --name eks-game-eks-cluster --region eu-west-2
kubectl apply -f kubernetes/
```

5. **Update Route53 NS delegation and wait for certificates:**
```bash
kubectl get certificate --all-namespaces -w
```

[INSERT DEPLOYMENT SCREENSHOT HERE]

## CI/CD Pipelines

### Pipeline 1: Terraform Validation

Runs on infrastructure changes (`infra/**`).

**Process:**
- Format check and validation
- Checkov security scanning
- Terraform plan for review
- Manual deployment required

[INSERT TERRAFORM PIPELINE SCREENSHOT HERE]

### Pipeline 2: Docker Build & Deploy

Runs on application changes (`app/**`).

**Process:**
```
Code Change → Build Image → Trivy Scan → Push to ECR → 
Update Manifest → Git Commit → ArgoCD Sync → Deployment
```

[INSERT DOCKER PIPELINE SCREENSHOT HERE]

## Accessing Services

**Application:**
- URL: https://game.eks.hamsa-ahmed.co.uk
[INSERT APPLICATION SCREENSHOT HERE]

**ArgoCD:**
- URL: https://argocd.eks.hamsa-ahmed.co.uk
- Username: `admin`
- Password: `kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d`

[INSERT ARGOCD SCREENSHOT HERE]

**Grafana:**
- URL: https://grafana.eks.hamsa-ahmed.co.uk
- Username: `admin`
- Password: `admin123`

[INSERT GRAFANA DASHBOARD SCREENSHOT HERE]

## Monitoring

Prometheus collects metrics from the cluster, nodes, pods, and NGINX Ingress. Grafana provides visualization with pre-configured dashboards:

- Kubernetes Cluster Overview
- Node Metrics
- NGINX Ingress Traffic
- Pod Resource Usage

[INSERT MONITORING SCREENSHOT HERE]

## Security

**Infrastructure:**
- Checkov IaC security scanning (57 checks passed)
- Private subnets for worker nodes
- IAM roles with least privilege
- Security groups limiting access

**Containers:**
- Trivy vulnerability scanning (0 vulnerabilities found)
- Minimal base image (nginx:alpine)
- No hardcoded secrets

**Network:**
- TLS 1.2+ encryption
- Let's Encrypt production certificates
- Automated certificate renewal

## Scaling

Horizontal Pod Autoscaler configured:
- Min replicas: 2
- Max replicas: 10
- Target CPU: 70%

Application automatically scales based on load.

## Technology Stack

- **IaC:** Terraform
- **Cloud:** AWS (EKS, VPC, Route53, ECR, IAM)
- **Container:** Docker
- **Orchestration:** Kubernetes 1.31
- **GitOps:** ArgoCD
- **Monitoring:** Prometheus, Grafana
- **Security:** cert-manager, Trivy, Checkov
- **CI/CD:** GitHub Actions

## Teardown
```bash
cd infra
./tear-down.sh
```

The script handles LoadBalancer deletion, DNS cleanup, and infrastructure destruction.

## Common Issues

**Certificates pending:** Wait 15-20 minutes for DNS propagation after infrastructure changes.

**ArgoCD out of sync:** Click "Sync" in ArgoCD UI to manually trigger deployment.

**Terraform state locked:** Use `terraform force-unlock <lock-id>` to release.

## Key Learnings

- DNS propagation takes time - patience beats troubleshooting
- GitOps provides audit trails and easy rollbacks
- ExternalDNS eliminates manual DNS management
- Separating Terraform validation from deployment simplifies CI/CD

## License

MIT License

## Author

Hamsa Ahmed