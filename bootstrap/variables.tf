variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "github_repos" {
  description = "GitHub repositories with their service account config and IAM roles"
  type = map(object({
    sa_id = string
    roles = list(string)
  }))
  default = {
    "mingjie-li/kip-infra" = {
      sa_id = "github-actions-tf"
      roles = ["roles/editor"]
    },

    "mingjie-li/kip" = {
      sa_id = "kip-gar-sa"
      roles = ["roles/artifactregistry.writer"]
    }
  }
}

variable "environments" {
  description = "List of environments to create state buckets for"
  type        = list(string)
  # default     = ["dev", "staging", "prod"]
  default = ["dev"]
}
