terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "imagebuilder-terraform"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}

