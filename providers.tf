provider "random" {
}

provider "null" {
}

provider "aws" {
  region  = "eu-west-1"
  version = ">= 2.38.0"
}

data "aws_region" "current" {
}

data "aws_availability_zones" "available" {
}

data "aws_caller_identity" "current" {
}