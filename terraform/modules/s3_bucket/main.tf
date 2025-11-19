locals {
  tags = merge(var.additional_tags, {
    Component = "artifact-bucket"
  })
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.tags

  lifecycle {
    prevent_destroy = !var.force_destroy
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    transition {
      days          = var.lifecycle_days
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = var.acl
}

