terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------------------------
# Provider configuration
# Author: Aymen
# Rationale:
# - Pinning the `google` and `random` provider families provides reproducible
#   behaviour. We choose the `~>` operator to allow non-breaking minor updates.
# - Authentication is expected to be handled externally (gcloud auth, service
#   account with JSON key via env var, or CI secrets). This keeps the code
#   portable across developer laptops, CI, and automation pipelines.
# - If you run into provider version issues, update the `version` constraints
#   above carefully and run `terraform init -upgrade` in a controlled manner.
# ---------------------------------------------------------------------------