terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure bucket, dynamodb_table, key, and region per environment.
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Service     = "terraform-parse"
    }
  }
}

locals {
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "terraform-parse"
  }
}

module "network" {
  source             = "./modules/network"
  vpc_id             = var.vpc_id
  private_subnet_ids = var.subnet_ids
}

module "eks" {
  source              = "./modules/eks"
  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.network.vpc_id
  subnet_ids          = module.network.private_subnet_ids
  desired_capacity    = var.node_desired_capacity
  min_capacity        = var.node_min_capacity
  max_capacity        = var.node_max_capacity
  instance_types      = var.node_instance_types
  environment         = var.environment
  additional_tags     = local.tags
  enable_cluster_logs = var.enable_cluster_logs
}

module "artifact_bucket" {
  source          = "./modules/s3_bucket"
  bucket_name     = var.bucket_name
  acl             = var.bucket_acl
  environment     = var.environment
  force_destroy   = var.bucket_force_destroy
  versioning      = var.bucket_versioning
  lifecycle_days  = var.bucket_lifecycle_days
  additional_tags = local.tags
}
