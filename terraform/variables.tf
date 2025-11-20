variable "project" {
  description = "Top-level project slug used for tagging and naming."
  type        = string
  default     = "tripla"
}

variable "environment" {
  description = "Deployment environment identifier (dev/stage/prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_id" {
  description = "Existing VPC ID to host the EKS cluster."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs spread across at least two AZs."
  type        = list(string)
  default     = []
}

variable "cluster_name_override" {
  description = "Optional custom cluster name. Defaults to <project>-<env>-eks."
  type        = string
  default     = null
}

variable "cluster_version" {
  description = "EKS control plane version."
  type        = string
  default     = "1.33"
}

variable "enable_cluster_public_access" {
  description = "Expose the Kubernetes API publicly."
  type        = bool
  default     = false
}

variable "enable_cluster_private_access" {
  description = "Expose the Kubernetes API privately within the VPC."
  type        = bool
  default     = true
}

variable "cluster_log_types" {
  description = "Control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "node_groups" {
  description = "Map of EKS managed node group definitions."
  type        = map(any)
  default = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      capacity_type  = "ON_DEMAND"
    }
  }
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}

variable "s3_bucket_name_override" {
  description = "Optional override for the static assets bucket name."
  type        = string
  default     = null
}

variable "s3_force_destroy" {
  description = "Allow Terraform to destroy non-empty buckets."
  type        = bool
  default     = false
}

variable "s3_enable_versioning" {
  description = "Enable object versioning on the bucket."
  type        = bool
  default     = true
}

variable "s3_bucket_acl" {
  description = "Bucket ACL. Keep private unless a specific use-case requires otherwise."
  type        = string
  default     = "private"
}
