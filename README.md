# GCP Infra Automation

Author: Aymen

Project: Full-scale Infrastructure as Code (IaC) on Google Cloud Platform

This repository automates the deployment of a secure, production-minded
infrastructure on Google Cloud Platform using Terraform. It focuses on:

- Custom VPCs and private subnets
- Secure firewall rules (including IAP-based SSH)
- Private Service Access peering for managed services
- Private Cloud SQL (Postgres) instances without public IPs

The configuration and guidance in this repo are opinionated for a
development/test environment. The comments and defaults are written by me
(Aymen) and include notes on how to harden and adapt this setup for
production use.

## Architecture overview

- Custom VPC (`google_compute_network.vpc`) with auto_create_subnetworks = false
- Private subnet (`google_compute_subnetwork.private_subnet`) with VPC Flow Logs
  enabled and private Google access for reaching Google APIs without external
  IPs.
- Firewall rules to allow internal traffic, and to allow SSH only from
  Identity-Aware Proxy (IAP) IP ranges.
- Private Service Access: a reserved internal address range + a
  `google_service_networking_connection` so Cloud SQL can have private IPs.
- Cloud SQL (Postgres) instance without public IPv4, small tier for dev/test,
  and a generated name suffix to avoid collisions.

## Files of interest

- `main.tf` — Core resources (VPC, subnet, firewall, private service access,
  Cloud SQL resources). Contains detailed inline comments on design choices.
- `variables.tf` — Variable definitions and defaults. Sensitive variables are
  marked with `sensitive = true`.
- `terraform.tfvars` — Example/local variable values (excluded from git via
  `.gitignore`). Do not commit secrets to your repo.
- `provider.tf` — Provider configuration (google & random) and version
  constraints.
- `outputs.tf` — Useful outputs (VPC name, subnet name, Cloud SQL private IP
  & connection name).

## Prerequisites

- Terraform >= 1.0 (configured in `provider.tf`)
- Google Cloud SDK (optional but helpful): `gcloud`
- A GCP project and sufficient IAM permissions to create VPCs, subnetworks,
  service networking peering, and Cloud SQL instances.

Authentication options (pick one):

1. `gcloud auth application-default login` for user credentials (developer
   use).
2. A service account key and `GOOGLE_APPLICATION_CREDENTIALS` env var.
3. Use Workload Identity / CI/CD provider integration in a pipeline.

Note: Keep credentials out of source control. Use CI secret injection or
Google Secret Manager for production secrets.

## Quick start (local)

1. Initialize Terraform providers and modules:

```bash
terraform init
```

2. (Optional) Format files:

```bash
terraform fmt -recursive
```

3. Create a plan and inspect what will change:

```bash
terraform plan -out=tfplan -var-file="terraform.tfvars"
```

4. Apply the plan (use `-auto-approve` carefully):

```bash
terraform apply "tfplan"
```

Notes:

- If you don't want to use a local `terraform.tfvars`, pass variables via
  `-var 'project_id=...' -var 'db_password=...'` or integrate secrets via your
  pipeline.
- `terraform validate` can be used to validate configurations but may need
  proper credentials for some providers.

## Variables

Important variables are in `variables.tf`. Key ones:

- `project_id` (string) — GCP project ID.
- `region` (string) — Default region, default `europe-west9`.
- `zone` (string) — Default zone, default `europe-west9-a`.
- `vpc_cidr` (string) — CIDR for the VPC (default `10.0.0.0/16`). Avoid
  conflicts with on-prem or peered networks.
- `subnet_cidr` (string) — CIDR for the private subnet (default `10.0.1.0/24`).
- `db_password` (sensitive string) — Password for the DB user. Marked
  `sensitive = true` and should be provided via secret manager for production.

Example (local, NOT recommended for production):

```hcl
project_id  = "xxxxxxxxxxx"
region      = "europe-west9"
db_password = "admin"
```

## Outputs

See `outputs.tf`. Key outputs include:

- `vpc_name` — Name of the created VPC.
- `private_subnet_name` — Name of the private subnet.
- `cloud_sql_private_ip` — Private IP address assigned to the Cloud SQL
  instance.
- `cloud_sql_connection_name` — Useful for connectors and Cloud SQL proxy.

## Security & best practices

- Do NOT store real secrets in `terraform.tfvars` under source control. Use
  Google Secret Manager, Vault, or your CI provider's secret store.
- Lock down firewall rules to the minimum required.
- Use `deletion_protection = true` on production databases to avoid
  accidental deletes.
- Apply IAM least privilege for service accounts and users that run Terraform.
- Consider enabling `terraform state` encryption at rest and storing the
  remote state in a secure backend (e.g., Google Cloud Storage with proper
  IAM and bucket retention/lifecycle rules).

## Production hardening suggestions

- Use private GKE/compute + private Cloud SQL with Cloud NAT for controlled
  egress.
- Configure backups and point-in-time recovery for Cloud SQL.
- Enable logging and monitoring (Stackdriver / Cloud Monitoring, VPC Flow
  Logs, and Cloud SQL insights).
- Use remote state with state locking and versioning (GCS backend + KMS).

## Troubleshooting

- If `google_service_networking_connection` fails, verify that the reserved
  range doesn't overlap with other networks and that the service networking
  API is enabled for your project.
- If Cloud SQL provisioning hangs, check quotas and ensure the private
  peering completed successfully.

## Next steps I recommend

1. Move the DB password into Google Secret Manager and update the Terraform
   run to fetch it at runtime (or use a CI secret injection).
2. Add a `terraform.tfvars.example` file with placeholders and remove the real
   `terraform.tfvars` from local dev copies.
3. Add a CI pipeline (GitHub Actions or Cloud Build) to run `terraform fmt`,
   `terraform validate`, and `terraform plan` on PRs; apply can be gated to
   protected branches.


