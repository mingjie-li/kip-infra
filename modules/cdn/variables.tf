variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "domain" {
  description = "Domain name for the static site (e.g. dev.kube-intel.com)"
  type        = string
}

variable "zone_name" {
  description = "Cloud DNS managed zone name"
  type        = string
}
