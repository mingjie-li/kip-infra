output "zone_name" {
  description = "DNS managed zone name"
  value       = google_dns_managed_zone.zone.name
}

output "name_servers" {
  description = "Name servers for the DNS zone"
  value       = google_dns_managed_zone.zone.name_servers
}
