terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sts.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com",
    "dns.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# State buckets — one per environment
resource "google_storage_bucket" "tfstate" {
  for_each = toset(var.environments)

  name     = "${var.project_id}-tfstate-${each.value}"
  location = var.region
  project  = var.project_id

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
}

# Service accounts for GitHub Actions — one per repo
resource "google_service_account" "github_actions" {
  for_each = var.github_repos

  account_id   = each.value.sa_id
  display_name = "GitHub Actions - ${each.key}"
  project      = var.project_id
}

# Grant each SA its configured roles
locals {
  sa_role_bindings = flatten([
    for repo, config in var.github_repos : [
      for role in config.roles : {
        key  = "${repo}:${role}"
        repo = repo
        role = role
      }
    ]
  ])
}

resource "google_project_iam_member" "github_actions_roles" {
  for_each = { for b in local.sa_role_bindings : b.key => b }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.github_actions[each.value.repo].email}"
}

# Grant the infra SA access to state buckets
resource "google_storage_bucket_iam_member" "tfstate_admin" {
  for_each = google_storage_bucket.tfstate

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_actions["mingjie-li/kip-infra"].email}"
}

# Enable Storage API on the GCS project
resource "google_project_service" "gcs_project_apis" {
  project            = var.gcs_project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# Grant the infra SA storage admin on the GCS project so it can manage buckets
resource "google_project_iam_member" "gcs_project_storage_admin" {
  project = var.gcs_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions["mingjie-li/kip-infra"].email}"
}

# Workload Identity Federation
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  project                   = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository in [${join(", ", [for repo, _ in var.github_repos : "\"${repo}\""])}]"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow each repo to impersonate its own service account
resource "google_service_account_iam_member" "workload_identity_user" {
  for_each = var.github_repos

  service_account_id = google_service_account.github_actions[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${each.key}"
}
