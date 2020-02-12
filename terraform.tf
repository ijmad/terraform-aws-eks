terraform {
  backend "s3" {
    bucket = "ijmad-terraform"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}