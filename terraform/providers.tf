terraform {
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "3.84.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "3.58.0"
    }

  }
}

provider "google" {
  # Configuration options
}

provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}