terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  cluster_name = coalesce(
    var.cluster_name_override,
    "${local.name_prefix}-eks"
  )
  static_assets_bucket = coalesce(
    var.s3_bucket_name_override,
    replace("${local.name_prefix}-static-assets", "_", "-")
  )
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

provider "aws" {
  region = var.aws_region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  enable_irsa = true

  cluster_endpoint_public_access  = var.enable_cluster_public_access
  cluster_endpoint_private_access = var.enable_cluster_private_access
  cluster_enabled_log_types       = var.cluster_log_types

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    disk_size      = 50
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 4
    desired_size   = 2
    labels = {
      Environment = var.environment
    }
    taints = []
  }

  eks_managed_node_groups = var.node_groups

  tags = local.common_tags
}

resource "aws_s3_bucket" "static_assets" {
  bucket        = local.static_assets_bucket
  force_destroy = var.s3_force_destroy

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = var.s3_enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  acl    = var.s3_bucket_acl
}
