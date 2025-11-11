// ---------------------------------------------------------------------------
// Project variables for: GCP Infra Automation
// Purpose: Keep all configurable values for the Terraform-managed GCP
// infrastructure in one place. These variables are intentionally minimal and
// opinionated for a demo/dev environment (custom VPC, private subnets, Cloud
// SQL without public IPs). Change defaults carefully for production.
// ---------------------------------------------------------------------------

variable "project_id" {
  description = "L'ID de votre projet GCP"
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

// CIDR range for the custom VPC. Keep this private and avoid conflicts with
// on-premises or peered networks. Example: 10.0.0.0/16
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