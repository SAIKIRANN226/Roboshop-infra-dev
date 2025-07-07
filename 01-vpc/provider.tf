terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.31.0"
    }
  }

  backend "s3" {
    bucket = "your-bucket" # Create a different bucket and dynamodb table for Dev environment
    key    = "your-key"
    region = "us-east-1"
    dynamodb_table = "your-dynamodb-table"
  }
}

provider "aws" {
  region = "us-east-1"
}