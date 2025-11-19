variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default     = "ap-northeast-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment label"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of dev, staging, prod."
  }
}

variable "cluster_name" {
  type        = string
  description = "Base EKS cluster name"
  default     = "tripla-eks"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.29"
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for worker nodes"
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types used by the node group"
  default     = ["t3.medium"]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "Provide at least one instance type."
  }
}

variable "node_desired_capacity" {
  type        = number
  description = "Desired nodes for the managed node group"
  default     = 2

  validation {
    condition     = var.node_desired_capacity >= 1
    error_message = "Desired capacity must be >= 1."
  }
}

variable "node_min_capacity" {
  type        = number
  description = "Minimum nodes for the managed node group"
  default     = 1

  validation {
    condition     = var.node_min_capacity >= 1
    error_message = "Minimum capacity must be >= 1."
  }
}

variable "node_max_capacity" {
  type        = number
  description = "Maximum nodes for the managed node group"
  default     = 4

  validation {
    condition     = var.node_max_capacity >= var.node_min_capacity
    error_message = "Max capacity must be >= min capacity."
  }
}

variable "enable_cluster_logs" {
  type        = bool
  description = "Toggle EKS control plane logging"
  default     = true
}

variable "bucket_name" {
  type        = string
  description = "Artifact bucket name"
}

variable "bucket_acl" {
  type        = string
  description = "Bucket ACL policy"
  default     = "private"

  validation {
    condition = contains(
      ["private", "public-read", "public-read-write", "authenticated-read"],
      var.bucket_acl
    )
    error_message = "Bucket ACL is invalid."
  }
}

variable "bucket_force_destroy" {
  type        = bool
  description = "Allow force destroy for S3 bucket"
  default     = false
}

variable "bucket_versioning" {
  type        = bool
  description = "Enable bucket versioning"
  default     = true
}

variable "bucket_lifecycle_days" {
  type        = number
  description = "Days before moving objects to colder storage"
  default     = 30
}
