
output "billing_api_key" {
  value       = google_apikeys_key.billing.key_string
  description = "API key for accessing Google Cloud Billing API"
  sensitive   = true
}

output "otel_service_account_email" {
  value       = google_service_account.otel_collector.email
  description = "Service account email for the otel-collector"
}