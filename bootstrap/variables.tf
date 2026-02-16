variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "github_repo" {
  description = "GitHub repository in the format owner/repo"
  type        = string
}

variable "environments" {
  description = "List of environments to create state buckets for"
  type        = list(string)
  # default     = ["dev", "staging", "prod"]
  default     = ["dev"]
}
