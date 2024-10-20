terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "AKIAU6VTTJG4M6TAX7UR"
  secret_key = "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"
}

provider "aws" {
  region = var.aws_region
  alias = "singapore"
}

provider "aws" {
  region = "eu-west-1"
  alias = "ireland"
}


