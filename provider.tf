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
}

provider "aws" {
  region = var.aws_region
  alias = "singapore"
}

provider "aws" {
  region = "eu-west-1"
  alias = "ireland"
}


