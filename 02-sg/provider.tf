terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }

  backend "s3" {
    bucket         = "saifundevops"
    key            = "sg"
    region         = "us-east-1"
    dynamodb_table = "saifundevopstable"
  }
}

provider "aws" {
  region = "us-east-1"
}