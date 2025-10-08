terraform {
  required_providers {
    awscc = {
      source  = "hashicorp/awscc"
      version = ">=1.57.0, < 1.58.0" # 1.58.0 is broken
    }
  }
  required_version = ">= 1.5.0"
}

provider "awscc" {
  region = var.region
}