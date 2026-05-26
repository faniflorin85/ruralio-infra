###############################################################################
# variables.tf — Variabile configurabile
###############################################################################

variable "aws_region" {
  description = "Regiunea AWS în care se creează resursele"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Numele proiectului, folosit ca prefix pentru numele resurselor"
  type        = string
  default     = "ruralio"
}

variable "vpc_cidr" {
  description = "Blocul CIDR pentru VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Blocul CIDR pentru subreteaua publică"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Blocul CIDR pentru subreteaua privată"
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "Tipul instanței EC2"
  type        = string
  default     = "t3.micro"
}


variable "github_repo" {
  description = "Repository-ul GitHub în format owner/repo (pentru OIDC trust policy)"
  type        = string
  # ex: "numele-tau/ruralio-infra"
}

variable "ssh_public_key" {
  description = "Conținutul cheii SSH publice (~/.ssh/ruralio.pub) — setat via secret în GitHub Actions"
  type        = string
}
