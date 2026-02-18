output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.cluster.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gateway_ip" {
  description = "Static global IP for the GKE Gateway load balancer"
  value       = var.enable_gateway_api ? google_compute_global_address.gateway[0].address : null
}

output "gateway_ip_name" {
  description = "Name of the static IP resource (reference in K8s Gateway annotation: networking.gke.io/load-balancer-ip)"
  value       = var.enable_gateway_api ? google_compute_global_address.gateway[0].name : null
}

output "gateway_certmap_name" {
  description = "Certificate Manager certificate map name (reference in K8s Gateway annotation: networking.gke.io/certmap)"
  value       = local.create_gateway_cert ? google_certificate_manager_certificate_map.gateway[0].name : null
}
