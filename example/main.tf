terraform {
  required_version = "=1.9.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=5.60.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.6.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "=4.0.5"
    }
  }

  backend "s3" {
    bucket         = "terraform-o2ym9tux"
    dynamodb_table = "terraform-state-lock"
    key            = "terraform/airport-atl/terraform.tfstate"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = local.aws_region
}

module "airport" {
  source  = "cloudboss/airport/aws"
  version = "0.1.0"

  ami         = local.ami
  database    = local.database
  dns         = local.dns
  kms_key_ids = local.kms_key_ids
  stack_key   = local.stack_key
  subnet_ids  = local.subnet_ids
  tags        = local.tags
  vpc_id      = local.vpc_id
  web         = local.web
  workers     = local.workers
}
