variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "acl" {
  type        = string
  default     = "private"
  description = "ACL applied to the bucket"
}

variable "environment" {
  type        = string
  description = "Environment label"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Whether to allow force destroy"
}

variable "versioning" {
  type        = bool
  default     = true
  description = "Enable bucket versioning"
}

variable "lifecycle_days" {
  type        = number
  default     = 30
  description = "Days before transitioning objects to Glacier"
}

variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "Common tags"
}

