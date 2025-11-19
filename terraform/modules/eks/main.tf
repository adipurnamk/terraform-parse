module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  eks_managed_node_group_defaults = {
    ami_type        = "AL2_x86_64"
    disk_size       = 50
    instance_types  = var.instance_types
    desired_size    = var.desired_capacity
    min_size        = var.min_capacity
    max_size        = var.max_capacity
    capacity_type   = "ON_DEMAND"
  }

  enable_irsa                   = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cloudwatch_log_group_retention_in_days = 7
  cluster_enabled_log_types = var.enable_cluster_logs ? [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ] : []

  tags = merge(var.additional_tags, {
    Component = "eks-cluster"
  })
}

