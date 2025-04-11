provider "aws" {
  alias   = "principal"
  region  = var.aws_region
  profile = var.profile
  
  default_tags {
    tags = merge(var.common_tags, {
      environment = var.environment
      project     = var.project
      client      = var.client
    })
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.31.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=3.0.0"
    }
  }
  required_version = ">= 1.0.0"
}
