# LocalStack backend configuration for local testing
# This file should be used when testing Terraform with LocalStack
# Usage: terraform init -backend-config=localstack-backend.tf

terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://localhost:4566"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}

