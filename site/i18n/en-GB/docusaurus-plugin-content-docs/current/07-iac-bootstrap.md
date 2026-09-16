---
title: Infrastructure as Code bootstrap
description: Replace Service Account key files with Workload Identity Federation, plus Terraform state version control and CI/CD bootstrap patterns.
keywords: [Terraform state, Workload Identity Federation, WIF, CI/CD, terraform-example-foundation]
sidebar_position: 7
---

# 7. Infrastructure as Code Bootstrap

Every Terraform sub-project in the earlier chapters ([`organization-policies/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies), [`iam-bindings/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/iam-bindings), [`network-design/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/network-design), and so on) defaults to "someone runs `terraform apply` from their own laptop." Production shouldn't stay at that stage — where the state file lives, whose credentials can apply it, and whether a PR review gates every apply all need a shared CI/CD foundation. That's exactly what the `0-bootstrap` stage of Google's own reference architecture, [`terraform-example-foundation`](https://github.com/terraform-google-modules/terraform-example-foundation), solves.

That reference architecture is split into several stages, with `0-bootstrap` as the foundation everything else builds on:

| Stage | Contents |
| --- | --- |
| **0-bootstrap** | Seed project, the GCS bucket used for Terraform state, the CI/CD pipeline, and a dedicated Service Account per stage |
| 1-org | The shared folder (logging, KMS, SCC notifications) and the networking folder |
| 2-environments | Per-environment (dev/non-prod/prod) folders, each with its own KMS/Secret project |
| 3-networks-svpc **or** 3-networks-hub-and-spoke | Pick one: Shared VPC or hub-and-spoke (matching the decision made in [network architecture design](/network-design/architecture)) — not both |
| 4-projects | Business-unit service projects, attached to the Shared VPC |

`0-bootstrap` specifically does two things:

1. **Puts Terraform state into a version-controlled GCS bucket** (`versioning { enabled = true }`) rather than leaving it on someone's laptop — a lost or conflicting local state file is one of the most common, and most avoidable, Terraform incidents.
2. **Authenticates CI/CD using [Workload Identity Federation (WIF)](https://docs.cloud.google.com/iam/docs/workload-identity-federation)**, with no downloaded Service Account key file.

:::warning
A Service Account's JSON key file is a long-lived credential — once it leaks, it keeps working until someone notices and revokes it. [Google's own best-practice guidance](https://docs.cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys) lists the risks: credential leakage, privilege escalation, and a lack of traceability (there's no way to prove who actually used that key to do what). Their conclusion, verbatim: "avoid user-managed service account keys, and use another authentication method wherever possible." For external CI/CD platforms like GitHub Actions or GitLab CI, switching to WIF lets the pipeline authenticate to GCP with short-lived, dynamically issued credentials — removing the "leaked key file" attack surface at the root.
:::

This project's own CI/CD bootstrap (state bucket + WIF pool) lives in the [`iac-bootstrap/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/iac-bootstrap) sub-project. If you want the full, official multi-stage landing-zone deployment pipeline, adopting [`terraform-example-foundation`](https://github.com/terraform-google-modules/terraform-example-foundation) directly will save you far more effort than rebuilding it from scratch.
