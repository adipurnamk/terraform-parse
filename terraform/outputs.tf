output "cluster_id" {
  description = "Provisioned EKS cluster id"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Provisioned cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "Cluster OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "artifact_bucket_id" {
  description = "Artifact bucket name"
  value       = module.artifact_bucket.bucket_id
}
