---
title: SME quickstart
description: A trimmed-down Terraform stack for small and medium businesses onboarding to GCP for the first time — one apply provisions folders/projects, an Organization Policy subset, IAM, a Shared VPC and centralised audit logging, with a clear upgrade path to the full enterprise architecture.
keywords: [SME, SMB, GCP quickstart, Terraform, Shared VPC, HA VPN]
sidebar_position: 1
---

# 9. SME Quickstart

The earlier chapters describe the **full enterprise onboarding flow** — covering multi-environment setups, a complete CIS-aligned policy set, and other complexity that only large enterprises need. If your company just needs a minimal, cost-controlled baseline — "nothing that would cause an incident if skipped, nothing that blows the budget if enabled" — use [`sme-quickstart/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/sme-quickstart) instead: a trimmed-down Terraform stack that provisions a basic governance baseline in a single `terraform apply`, while reusing the same enterprise-grade Terraform sub-projects from the earlier chapters — so growing into the full architecture later doesn't require a rewrite.

## What's in, what's out

| Chapter | Included | Deferred (add later if needed) |
| --- | --- | --- |
| [Folders/Projects](/organization-setup/folders-projects) | Two folders: `network` (Shared VPC host project) and `service` (workload projects); a dedicated logging project attached directly to the Organization | Multi-environment (dev/non-prod/prod) or subsidiary-based folder splits |
| [Organization Policies](/organization-setup/organization-policies) | 8 hand-picked, high-value policies (restrict domain sharing, disable SA key creation, disable VM external IPs, disable the default network, require OS Login, uniform bucket-level access, restrict Cloud SQL public IP, restrict resource locations) | The full 35-policy catalogue (CIS Benchmark plus AI/Vertex AI-specific extensions) |
| [IAM](/organization-setup/iam-bindings) | All 5 minimum-viable admin groups, bound at organization/billing level | (already lightweight — unchanged from the enterprise version) |
| [Networking](/network-design/architecture) | Shared VPC + hierarchical firewall baseline | [Hybrid connectivity](/network-design/hybrid-connectivity) is off by default — see "Optional: VPN" below |
| [Logging](/logging/aggregated-sink) | A dedicated logging project + an org-level aggregated sink, Cloud Storage archival only | Log Analytics (BigQuery), Pub/Sub SIEM export, and [Data Access audit logs](/logging/audit-logs) |
| [Security products](/security-products/scc) | None | SCC, VPC-SC, CMEK, Secret Manager, Cloud Armor, Binary Authorization — add once there's an actual requirement |
| [Backup & DR](/backup-dr) | None | Native Cloud SQL/Persistent Disk backup mechanisms are enough for now |
| [IaC bootstrap](/iac-bootstrap) | Recommended as a first step | — |

## Folder layout

```
Organization
├── Folder: network      → Shared VPC host project (VPN resources also live here)
├── Folder: service       → Workload/service projects
└── Project: logging      → Attached directly to the Organization, not inside any folder
```

The logging project is deliberately kept out of the `network` and `service` folders — whoever can read or alter audit logs shouldn't be the same people managing networking or workloads. Attaching it directly to the Organization keeps that permission boundary clean.

## Optional: VPN (hybrid connectivity)

If there's no on-prem site to connect, skip this entirely — `enable_vpn` defaults to `false`, and `terraform plan` produces no VPN-related resources at all.

Once you do need to connect to an on-prem network:

1. Agree with the on-prem network team ahead of time on: the on-prem device's ASN, its public IP(s) (one or two), the BGP link-local IP ranges, and the IKE shared secret.
2. Set `enable_vpn = true` and fill in the peer details (see the repo's [`terraform.tfvars.example`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/sme-quickstart/examples/root/terraform.tfvars.example)).
3. **Never** put the shared secret in `terraform.tfvars` — pass it through an environment variable instead.

For the technical details (HA VPN + Cloud Router BGP, SLA tiers), see [Hybrid connectivity](/network-design/hybrid-connectivity). Dedicated/Partner/Cross-Cloud Interconnect require a physical circuit order process and have no corresponding module here.

:::tip
This is an **MVP, not an end state**. As the company grows into needing finer-grained governance, switch directly to the full enterprise Terraform sub-projects — the SME version already calls them directly rather than duplicating their logic, so there's no architecture rewrite involved.
:::

## Getting started

```bash
cd sme-quickstart/examples/root
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: org_id, domain, billing_account_id,
# host_project_id, service_project_ids, logging_project_id, subnets

terraform init
terraform plan
terraform apply
```

For the full prerequisites, the IAM roles the applying account needs, and known limitations, see [`sme-quickstart/README.md`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/sme-quickstart) in the repo.
