variable "vpc_id" {
  description = "Existing VPC ID where the cluster will run"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by worker nodes"
  type        = list(string)
}

