resource "google_artifact_registry_repository" "docker" {
  repository_id = "kip-${var.environment}"
  project       = var.project_id
  location      = var.region
  format        = "DOCKER"
  description   = "Docker repository for kip ${var.environment}"
}
