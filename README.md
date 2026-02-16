# kip-infra

GCP infrastructure managed with Terraform. Deploys a GKE cluster across three environments (dev, staging, prod) with GitHub Actions CI/CD using Workload Identity Federation.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- A GCP project with billing enabled
- A GitHub repository

## Initial Setup

### 1. Bootstrap GCP resources

The bootstrap module creates the Terraform state buckets, a CI/CD service account, and Workload Identity Federation for GitHub Actions.

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars  # edit with your values
terraform init
terraform apply
```

### 2. Configure GitHub

After bootstrap, set these GitHub repository variables (Settings > Secrets and variables > Actions > Variables):

| Variable | Value |
|---|---|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Output from bootstrap: `workload_identity_provider` |
| `GCP_SERVICE_ACCOUNT` | Output from bootstrap: `service_account_email` |

Configure GitHub Environments (`dev`, `staging`, `prod`) under Settings > Environments. Add required reviewers for `staging` and `prod`.

### 3. Deploy

Push to `main` or open a pull request. The CI/CD pipeline will handle planning and applying.

## Structure

```
bootstrap/          # One-time setup (state buckets, WIF, SA)
modules/
  network/          # VPC, subnets, Cloud NAT
  gke/              # GKE cluster and node pools
environments/
  dev/              # Development environment
  staging/          # Staging environment
  prod/             # Production environment
.github/workflows/  # CI/CD pipelines
```
