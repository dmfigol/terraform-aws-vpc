module "vpc" {
  source = "../../src//prefix-lists"

  prefix_lists = {}
}

provider "aws" {
  region = "eu-west-2"
}

provider "awscc" {
  region = "eu-west-2"
}