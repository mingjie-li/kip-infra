resource "google_dns_managed_zone" "zone" {
  name        = "kip-${var.environment}-zone"
  project     = var.project_id
  dns_name    = "${var.domain}."
  description = "DNS zone for ${var.domain}"
  dnssec_config {
    state = "on"
  }
}
