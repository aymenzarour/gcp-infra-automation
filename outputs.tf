output "vpc_name" {
  description = "Le nom du VPC créé"
  value       = google_compute_network.vpc.name
}

output "private_subnet_name" {
  description = "Le nom du sous-réseau privé"
  value       = google_compute_subnetwork.private_subnet.name
}

output "cloud_sql_private_ip" {
  description = "L'adresse IP privée de l'instance Cloud SQL"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "cloud_sql_connection_name" {
  description = "Le nom de connexion de l'instance pour les connecteurs Cloud SQL"
  value       = google_sql_database_instance.postgres.connection_name
}

# ---------------------------------------------------------------------------
# Outputs for GCP Infra Automation
# Notes:
# - These outputs expose essential identifiers and private connection details
#   needed for application deployment (for example, using the Cloud SQL
#   connection name with the Cloud SQL Proxy or Serverless connectors).
# - Avoid printing sensitive information here. We only output names and the
#   private IP address used internally — the actual DB password is marked
#   sensitive in `variables.tf` and is not emitted here.
# ---------------------------------------------------------------------------