# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Ruralio** is an AWS infrastructure + static website project for a Romanian vacation rental ("Casa Dunărea", Orșova). It provisions an EC2-hosted Nginx server via Terraform and deploys a single-page marketing site through GitHub Actions.

## Repository Structure

```
terraform/      # All infrastructure code (one file per concern)
site/           # Static HTML/CSS website + images
.github/workflows/deploy.yml  # CI/CD pipeline
```

## Terraform Commands

All commands run from the `terraform/` directory:

```bash
terraform init                    # Initialize S3 backend + providers
terraform fmt -check              # Validate formatting
terraform validate                # Validate configuration
terraform plan -input=false       # Preview changes (used on PRs)
terraform apply -auto-approve     # Apply changes (used on main branch push)
terraform output -raw instance_public_ip  # Get deployed EC2 IP
```

## One-Time Setup (local or new AWS account)

```bash
# Create S3 state bucket + DynamoDB lock table
aws s3api create-bucket --bucket ruralio-terraform-state-332241527149 --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
aws s3api put-bucket-versioning --bucket ruralio-terraform-state-332241527149 --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name ruralio-terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region eu-central-1

# SSH key (imported into EC2 as key pair)
ssh-keygen -t ed25519 -f ~/.ssh/ruralio -N ""

# Configure variables
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set ssh_allowed_cidr (your IP/32) and github_repo (owner/repo)
```

## Architecture

**Infrastructure** (Terraform, AWS eu-central-1):
- VPC (10.0.0.0/16) with a public subnet (10.0.1.0/24) and a reserved private subnet (10.0.2.0/24)
- EC2 t3.micro (Ubuntu 22.04) with Elastic IP, 8 GB encrypted gp3 volume
- Nginx installed via `user-data.sh`; SSL via Certbot (manual post-deploy step)
- Security group: HTTP (80) + HTTPS (443) open to world, SSH (22) restricted to `ssh_allowed_cidr`
- OIDC federation (`github-oidc.tf`) grants GitHub Actions temporary AWS credentials — no static keys needed

**CI/CD** (`.github/workflows/deploy.yml`):
- **Pull request** → `terraform plan` only (read-only validation)
- **Push to main** → `terraform apply` then SCP `site/*` to `/var/www/html/` on the EC2 instance
- Pipeline reads instance IP from `terraform output` to connect for site deployment
- Requires GitHub secret `SSH_PRIVATE_KEY`

**Remote state**: S3 bucket `ruralio-terraform-state-332241527149` + DynamoDB table `ruralio-terraform-locks` for locking.

## Key Variables (`terraform.tfvars`)

| Variable | Default | Notes |
|---|---|---|
| `aws_region` | eu-central-1 | AWS region |
| `instance_type` | t3.micro | EC2 size |
| `vpc_cidr` | 10.0.0.0/16 | VPC address space |
| `ssh_allowed_cidr` | — | **Must set**: your IP in CIDR notation |
| `github_repo` | — | **Must set**: `owner/repo` for OIDC trust |

## Deployment Flow

```
git push → GitHub Actions
  ├─ terraform init / validate / plan
  ├─ terraform apply  →  EC2 instance + Elastic IP provisioned
  ├─ terraform output -raw instance_public_ip  →  capture IP
  └─ scp site/* → /tmp/ruralio-site
     ssh: sudo cp -r /tmp/ruralio-site/* /var/www/html/ && sudo systemctl reload nginx
```
