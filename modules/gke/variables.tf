variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the default node pool"
  type        = string
  default     = "e2-standard-2"
}

variable "min_node_count" {
  description = "Minimum number of nodes per zone"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes per zone"
  type        = number
  default     = 3
}

variable "disk_size_gb" {
  description = "Disk size in GB for each node"
  type        = number
  default     = 20
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "spot_vms" {
  description = "Use spot VMs for the default node pool"
  type        = bool
  default     = false
}

variable "enable_gateway_api" {
  description = "Enable GKE Gateway API and provision a static regional IP for the load balancer"
  type        = bool
  default     = true
}

variable "gateway_domain" {
  description = "Domain for the Gateway TLS certificate (e.g. api.dev.kube-intel.com). When set, a Certificate Manager cert and certmap are created."
  type        = string
  default     = ""
}

variable "gateway_dns_zone" {
  description = "Cloud DNS managed zone name for Gateway TLS DNS authorization (e.g. kip-dev-zone)"
  type        = string
  default     = ""
}

variable "gateway_dns_project_id" {
  description = "Project ID where the Cloud DNS zone lives. Defaults to var.project_id if empty."
  type        = string
  default     = ""
}
