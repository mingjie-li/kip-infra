output "workload_identity_provider" {
  description = "Workload Identity Provider resource name for GitHub Actions auth"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "service_account_email" {
  description = "Service account email for GitHub Actions"
  value       = google_service_account.github_actions.email
}

output "state_bucket_names" {
  description = "GCS bucket names for Terraform state per environment"
  value       = { for env, bucket in google_storage_bucket.tfstate : env => bucket.name }
}
