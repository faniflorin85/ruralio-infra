###############################################################################
# main.tf — Provider AWS + Backend pentru state
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remote: state-ul Terraform stă într-un bucket S3, cu lock în DynamoDB.
  # Bucket-ul și tabela trebuie să existe ÎNAINTE de `terraform init`.
  # (le-ai creat manual cu AWS CLI — vezi README.md)
  backend "s3" {
    bucket         = "ruralio-terraform-state-332241527149"
    key            = "infra/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "ruralio-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  # Fără chei aici! Provider-ul citește credențialele din mediu:
  # variabile de mediu, ~/.aws/credentials (profilul setat prin AWS_PROFILE),
  # sau rolul IAM asumat prin OIDC (în GitHub Actions).

  default_tags {
    tags = {
      Project   = "ruralio"
      ManagedBy = "terraform"
    }
  }
}
