locals {
  validated_subnets = distinct(var.private_subnet_ids)
}

output "vpc_id" {
  description = "VPC ID for downstream modules"
  value       = var.vpc_id
}

output "private_subnet_ids" {
  description = "Validated private subnet IDs"
  value       = local.validated_subnets
}

