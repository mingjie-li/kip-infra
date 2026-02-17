output "bucket_name" {
  description = "Name of the static files GCS bucket"
  value       = google_storage_bucket.static.name
}

output "bucket_url" {
  description = "GCS URL of the static files bucket"
  value       = google_storage_bucket.static.url
}

output "lb_ip" {
  description = "Global IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}
