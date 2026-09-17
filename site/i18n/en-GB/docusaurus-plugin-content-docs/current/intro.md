---
id: intro
title: GCP Enterprise Onboarding Guide
description: A complete guide to enterprise-tier Google Cloud onboarding — from Cloud Identity registration and Organization setup through network design, centralised logging and security products — with ready-to-apply Terraform modules.
keywords: [GCP, Google Cloud, enterprise onboarding, Cloud Identity, Terraform, org policy]
sidebar_position: 0
slug: /
---

# GCP Enterprise Onboarding Guide

This is a **start-from-scratch** guide to enterprise-tier Google Cloud onboarding. It runs from registering Cloud Identity and initialising your GCP Organization, through network design, centralised log management and security product rollout, to Infrastructure as Code bootstrapping — covering every governance decision an enterprise typically faces when adopting GCP in earnest.

Every chapter:

- **Cites official sources.** Content is written from official Google Cloud documentation (the Architecture Center, the Security Foundations Blueprint, individual product docs), with links back to the originals wherever a claim matters — nothing here is written from memory.
- **Ships with applicable Terraform.** Wherever a chapter has an implementation component, it links to the matching Terraform sub-project in the [GitHub repository](https://github.com/terensy/gcp-onboarding-workflow), ready for `terraform init/plan/apply`.
- **Explains trade-offs, not just steps.** Each chapter covers the *why* and the *what breaks if you skip this*, not only the *how* — this guide is written for people who have to make the decision, not just follow a checklist.

## Who this is for

- Cloud engineers/SREs setting up an enterprise-grade GCP environment for the first time
- Consultants who need to explain GCP governance architecture and Terraform automation to clients
- Technical leads who want to know which governance guardrails to put in place beyond "does it work"

## Start reading

Start from [1. Verify domain & initialise Cloud Identity](/cloud-identity/verify-domain), or jump straight to whichever chapter you're stuck on:

- [2. Organization setup](/organization-setup/folders-projects): folder/project hierarchy, Organization Policies, billing, IAM
- [3. GCP network design](/network-design/architecture): Shared VPC, hybrid connectivity, firewalls
- [4. Log management](/logging/audit-logs): Cloud Audit Logs, aggregated log sinks
- [5. Security products](/security-products/scc): SCC, VPC-SC, KMS, Secret Manager, Cloud Armor
- [6. Backup & disaster recovery strategy](/backup-dr)
- [7. Infrastructure as Code bootstrap](/iac-bootstrap)
- [8. Other governance topics](/governance/tagging): tagging/labelling, Support Plan
- [9. SME quickstart](/sme-quickstart/overview): just need a minimal baseline? Start here
- [10. AI infrastructure onboarding](/ai-onboarding/overview): rollout includes Vertex AI / Gemini Enterprise? Start here

## Source code and Terraform modules

The full source behind this guide — Terraform modules, policy catalogues, methodology write-ups — lives at
[github.com/terensy/gcp-onboarding-workflow](https://github.com/terensy/gcp-onboarding-workflow). Clone it directly, or open an issue.
