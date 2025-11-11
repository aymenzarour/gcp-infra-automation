// ---------------------------------------------------------------------------
// main.tf
// GCP Infra Automation — by Aymen
// This file provisions the core networking and a private Cloud SQL instance.
// Design goals:
// - Custom VPC with explicit subnets (no auto-created subnetworks).
// - Private Service Access peering so managed services (Cloud SQL) can get
//   private IP addresses inside the VPC.
// - Cloud SQL instance with no public IPv4 and credentials marked as
//   sensitive. This is intended for dev/test; tighten settings for prod.
// ---------------------------------------------------------------------------

// --- 1. VPC & NETWORKING ---
// Create a custom VPC. We disable auto subnets to keep full control over
// addressing and routing.
resource "google_compute_network" "vpc" {
  name                    = "main-vpc"
  auto_create_subnetworks = false
}

// Create a private subnet that will host internal resources (e.g., Cloud SQL).
// We enable private Google access so instances without external IPs can still
// reach Google APIs (e.g., for package updates or metadata access).
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  # VPC Flow Logs help with auditing and troubleshooting; configured here
  # with fine-grained settings appropriate for a demo environment.
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  # Allow access to Google APIs from private IPs in this subnet.
  private_ip_google_access = true
}

// --- 2. SECURITY (FIREWALL) ---
// Allow internal traffic within the VPC. In real environments, prefer
// more restrictive rules (least privilege) and use tags/service accounts
// to scope access.
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-traffic"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.vpc_cidr]
}

// Allow SSH only via IAP. This prevents exposing TCP/22 to the public internet
// and is the recommended Google pattern for secure bastion-style access.
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # CIDR range used by Google IAP. This narrows exposure to only Google's
  # IAP infrastructure.
  source_ranges = ["35.235.240.0/20"]
}

// --- 3. PRIVATE SERVICE ACCESS (for Cloud SQL private IP) ---
// Reserve an internal IP range for Google-managed services and create a
// service networking connection to enable private IPs for Cloud SQL.
resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

// --- 4. CLOUD SQL (Postgres) ---
// Create a small Cloud SQL instance without a public IP. We generate a
// short random suffix so the instance name is unique across projects.
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "postgres" {
  name             = "private-postgres-${random_id.db_name_suffix.hex}"
  region           = var.region
  database_version = "POSTGRES_15"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro" # Small, cost-effective instance for dev/test

    ip_configuration {
      ipv4_enabled    = false # Disable public IPv4 for security
      private_network = google_compute_network.vpc.id
    }

    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }
  }

  deletion_protection = false # Enable in production to avoid accidental deletions
}

// Create a database and a user. Password is provided via `var.db_password` and
// marked sensitive in `variables.tf`.
resource "google_sql_database" "database" {
  name     = "my-app-db"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "users" {
  name     = "app-user"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}

// ---------------------------------------------------------------------------
// Notes and next steps:
// - This configuration is opinionated for demonstration. For production harden
//   network rules (narrow CIDR blocks), enable stronger machine types, set
//   deletion_protection = true, and manage secrets via a secret manager.
// - Consider adding monitoring, alerting, and IAM roles for least privilege.
// ---------------------------------------------------------------------------