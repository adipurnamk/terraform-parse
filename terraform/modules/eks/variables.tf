variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the cluster"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for cluster networking"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets used by worker nodes"
}

variable "desired_capacity" {
  type        = number
  description = "Desired node count"
}

variable "min_capacity" {
  type        = number
  description = "Minimum node count"
}

variable "max_capacity" {
  type        = number
  description = "Maximum node count"
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for managed node group"
}

variable "environment" {
  type        = string
  description = "Deployment environment label"
}

variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags applied to cluster resources"
}

variable "enable_cluster_logs" {
  type        = bool
  default     = true
  description = "Whether to enable control plane logging"
}

