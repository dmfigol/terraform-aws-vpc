terraform {
  required_providers {
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = ">= 6.15.0"
    # }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">=1.57.0, < 1.58.0" # 1.58.0 is broken
    }
  }
  required_version = ">= 1.5.0"
}

# provider "aws" {
#   region = var.region
# }

provider "awscc" {
  region = var.region
} 