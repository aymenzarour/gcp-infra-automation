variable "project_id" {
  description = "L'ID du projet GCP"
  type        = string
}

variable "region" {
  description = "La région GCP par défaut"
  type        = string
  default     = "europe-west9" # Paris
}

variable "zone" {
  description = "La zone GCP par défaut"
  type        = string
  default     = "europe-west9-a"
}

// CIDR range for the custom VPC.
variable "vpc_cidr" {
  description = "Plage IP pour le VPC personnalisé"
  default     = "10.0.0.0/16"
}

// CIDR range for the private subnet that will host internal services
// (e.g., Cloud SQL). This is deliberately a small range for dev/test.
variable "subnet_cidr" {
  description = "Plage IP pour le sous-réseau privé"
  default     = "10.0.1.0/24"
}

// Database password: marked sensitive so Terraform hides it in logs and UI.
// For real projects, read this from a secret manager rather than a file.
variable "db_password" {
  description = "Mot de passe pour l'utilisateur de la base de données"
  type        = string
  sensitive   = true # Masque la valeur dans les logs Terraform
}
