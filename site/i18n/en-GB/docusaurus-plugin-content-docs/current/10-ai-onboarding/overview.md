---
title: AI Infrastructure Onboarding
description: Governance and guardrails to layer on top of the core enterprise onboarding for AI/ML workloads (Vertex AI, Gemini Enterprise) — Model Garden allow-listing, Model Armor semantic-layer protection, Sensitive Data Protection. Some items already ship with working Terraform.
keywords: [AI onboarding, Vertex AI, Gemini Enterprise, Model Armor, Sensitive Data Protection, GCP AI governance]
sidebar_position: 1
---

# 10. AI Infrastructure Onboarding

If your GCP rollout includes AI/ML workloads — mainly Vertex AI and Gemini Enterprise — most of the governance framework from earlier chapters (Organization Policies, IAM, networking, logging, security products) carries over as-is. An AI workload is still, fundamentally, a workload; it doesn't need its own separate governance category. This chapter covers what's genuinely AI-specific and not addressed elsewhere, matching the [`ai-onboarding/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding) Terraform sub-project.

:::tip
This sub-project is **still being built out**. Items marked "✅ Implemented" below have working Terraform that passes `terraform validate`; everything else is still at the planning stage. Before you act on anything, check the "current status" table in [`ai-onboarding/README.md`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/ai-onboarding/README.md) for the real state of each item.
:::

## Required vs optional

Regardless of your starting point, the following are recommended as day-one defaults:

| Item | Status | Notes |
| --- | --- | --- |
| AI org policy baseline | ✅ Implemented | `constraints/vertexai.allowedModels` (Model Garden allow-list) and `constraints/iam.automaticIamGrantsForDefaultServiceAccounts` (disables automatic default-SA grants), both added to the catalogue in [Organization Policies](/organization-setup/organization-policies) |
| Model Armor | ✅ Implemented | Prompt injection/jailbreak and malicious-URL detection; `enforcement_type` defaults to `INSPECT_ONLY` (dry-run) — switch to `INSPECT_AND_BLOCK` after an observation period |
| Sensitive Data Protection (PII) | ✅ Implemented | Detected PII is de-identified (masked) by default, not blocked outright; ships in the same Terraform module as Model Armor |
| AI use-case risk tiering & approval policy | 📝 Document only | Who signs off on a new AI use case, how often the Model Garden allow-list gets reviewed — pure governance policy, no GCP resource attached |
| AI-specific incident response runbook | 📝 Document only | Classification and escalation paths for events like a successful prompt injection or a model leaking PII |
| Advanced IAM group split, AI-specific CMEK, VPC-SC expansion, PSC network connectivity, advanced data governance, GPU/TPU capacity planning | ⬜ Optional | Evaluate based on team size and compliance requirements |
| AI Gateway (Apigee) / Agent Gateway | 🔀 Conditional | Only needed for multi-team/multi-app setups, third-party model integrations, or agentic workloads — see the decision table below |

## Quick start: Model Armor + Sensitive Data Protection

```bash
cd ai-onboarding/examples/root
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: project_id, location
# Keep enforcement_type as INSPECT_ONLY (dry-run) for the first pass

terraform init
terraform plan
terraform apply
```

Applying this creates:

- A Model Armor Template (prompt injection/jailbreak and malicious-URL detection, wired to the SDP template below)
- A Sensitive Data Protection Inspect + De-identify Template pair (detects email, phone number, credit card number, name and street address by default; national ID numbers are handled separately via a regex format check — not an official checksum validation, so confirm it meets your compliance needs before relying on it)

Full variable documentation and the reasoning behind each default live in [`ai-onboarding/modules/ai_guardrails/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding/modules/ai_guardrails).

## Do you need an AI Gateway?

An AI Gateway (Apigee AI Gateway / Google Cloud API Gateway's model routing) solves application/platform-layer problems — token/rate limiting, multi-model routing, centrally applying Model Armor policy. It is not a mandatory module:

| Condition | Recommendation |
| --- | --- |
| Single app, single team, Vertex AI only | Not needed — attach Model Armor directly to Vertex AI or the application |
| Multiple teams/apps needing unified billing and auditing | Needed — put Apigee in front as a mandatory ingress |
| Integrating third-party (non-Google) models, or need model failover | Needed — this is outside what Vertex AI's native mechanisms cover |
| Agentic workloads (Gemini Enterprise Agent Platform) | Evaluate Agent Gateway separately — a different product line from a general LLM API gateway |

## Explicitly out of scope

The following are deliberately excluded from this sub-project — they belong to the application/data team building on top of the platform, not the governance foundation:

- MLOps CI/CD pipelines, Model Registry version management
- Vertex AI Model Monitoring (training-serving skew, prediction drift detection)
- Vector DB/RAG pipeline technical design
- Agent application logic itself (tool wiring, prompt engineering)

For the full design rationale, the trade-offs behind each baseline default, the draft Responsible AI governance policy and the incident-response skeleton, see [`ai-onboarding/README.md`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/ai-onboarding/README.md).
