---
title: Plan GCP Organization Policies
description: Use Organization Policy to set governance guardrails at the org, folder or project level, and manage 35 policies mapped to the CIS Benchmark with Terraform.
keywords: [Organization Policy, org policy, CIS Benchmark, GCP governance]
sidebar_position: 2
---

# 2.2 Plan GCP Organization Policies

GCP Organization Policies let administrators set uniform constraints at the organisation, folder or project level — for example, restricting which regions resources can be created in, restricting external data sharing, or restricting which services are usable. Policies are inherited automatically down to folders and projects, and can be overridden further down the hierarchy. In short: they put governance guardrails around your whole GCP environment, so teams can operate freely within a compliant boundary.

Once a GCP Organization is enabled, a set of [default Organization Policies](https://docs.cloud.google.com/organization-policy/reference/org-policy-constraints#automatically_enforced_constraints) is already active. If your company's policy needs to meet the baseline CIS Benchmark, see the [`organization-policies/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies) Terraform sub-project:

- [Bilingual policy catalogue](https://github.com/terensy/gcp-onboarding-workflow/blob/main/organization-policies/docs/policy_catalog.md) — a Chinese/English side-by-side table of all 35 policies (including 2 AI/Vertex AI-specific extensions), mapped against [CIS Google Cloud Platform Foundation Benchmark v5.0.0](https://github.com/terensy/gcp-onboarding-workflow/blob/main/organization-policies/references/CIS_Google_Cloud_Platform_Foundation_Benchmark_v5.0.0.pdf).
- [Methodology write-up](https://github.com/terensy/gcp-onboarding-workflow/blob/main/organization-policies/docs/methodology.md) — how to decide, based on your own company's risk and business needs, which policies to enable, at what level, and with what values — rather than adopting the CIS recommendations wholesale.
- [Terraform module](https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies) — reads `policies_catalog.yaml` and uses `for_each` to generate `google_org_policy_policy` resources, ready for `terraform init/plan/apply`.
