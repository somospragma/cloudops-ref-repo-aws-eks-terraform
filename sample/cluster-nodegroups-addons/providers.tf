###########################################
############# AWS Provider ################
###########################################

provider "aws" {
  alias   = "principal"
  region  = var.aws_region
  profile = var.profile

  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT_NUMBER:role/ROLE_NAME"
  # }
  
  default_tags {
    tags = var.common_tags
  }
}

###########################################
# Version definition - Terraform - Providers
###########################################

terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.31.0"
    }
  }
}

