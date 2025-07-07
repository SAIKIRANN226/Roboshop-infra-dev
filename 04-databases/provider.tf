terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
  }

  backend "s3" {
    bucket         = "saifundevops"
    key            = "databases"
    region         = "us-east-1"
    dynamodb_table = "saifundevopstable"
  }
}

provider "aws" {
  region = "us-east-1"
}