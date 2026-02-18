variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "storage_project_id" {
  description = "GCP project ID for the static GCS bucket"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP zone for zonal GKE cluster (e.g. us-east1-b)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "min_node_count" {
  description = "Minimum nodes per zone"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum nodes per zone"
  type        = number
  default     = 2
}
