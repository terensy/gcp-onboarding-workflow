---
title: AI Infrastructure Onboarding
description: Governance and guardrails to layer on top of the core enterprise onboarding for AI/ML workloads (Vertex AI, Gemini Enterprise) — Model Garden allow-listing, Model Armor semantic-layer protection, Sensitive Data Protection.
keywords: [AI onboarding, Vertex AI, Gemini Enterprise, Model Armor, Sensitive Data Protection, GCP AI governance]
sidebar_position: 1
---

# 10. AI Infrastructure Onboarding

If your GCP rollout includes AI/ML workloads — mainly Vertex AI and Gemini Enterprise — most of the governance framework from earlier chapters (Organization Policies, IAM, networking, logging, security products) carries over as-is. An AI workload is still, fundamentally, a workload; it doesn't need its own separate governance category. This chapter covers what's genuinely AI-specific and not addressed elsewhere, matching the [`ai-onboarding/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding) Terraform sub-project.

## What's covered

| Area | Backing resource | Notes |
| --- | --- | --- |
| Model Garden allow-list | `constraints/vertexai.allowedModels` in [Organization Policies](/organization-setup/organization-policies) | Restricts which models and actions (predict/tune/deploy) are usable; the conservative default allows only Google's first-party Gemini family |
| Service account governance | Same catalogue, `constraints/iam.automaticIamGrantsForDefaultServiceAccounts` | Disables the automatic `roles/editor` grant to default service accounts |
| Semantic-layer protection (Model Armor) | `ai-onboarding/modules/ai_guardrails/` | Prompt injection/jailbreak detection, malicious-URL detection |
| PII detection & masking (Sensitive Data Protection) | Same module | Detected PII is de-identified (masked), not blocked outright |

## Quick start

```bash
cd ai-onboarding/examples/root
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: project_id, location
# Keep enforcement_type as INSPECT_ONLY (dry-run) for the first pass

terraform init
terraform plan
terraform apply
```

This creates a Model Armor Template wired to a Sensitive Data Protection Inspect + De-identify Template pair. `enforcement_type` defaults to `INSPECT_ONLY` (log findings, don't block traffic); once a monitoring period shows the findings are all expected violations, switch it to `INSPECT_AND_BLOCK` — the same dry-run-then-enforce pattern this guide uses for [VPC Service Controls](/security-products/vpc-service-controls).

Full variable documentation lives in [`ai-onboarding/modules/ai_guardrails/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding/modules/ai_guardrails).

## Governance decisions to make yourself

These don't have a matching Terraform resource — they're organisational policy, and worth settling before you apply the module above:

- **AI use-case risk tiering.** Which use cases count as high-risk (credit decisions, hiring screens, medical/legal advice) and need extra sign-off.
- **Model Garden approval process.** Who approves a new model, what the SLA is, how often the existing allow-list gets reviewed.
- **AI incident response.** Which escalation path a successful prompt injection or a model leaking PII goes through, who owns it, and how it's tiered.
- **GPU/TPU capacity and cost.** Who can request quota/reservations and who approves them; attribute cost using the same [labelling convention](/governance/tagging) as the rest of the guide.

## Do you need an AI Gateway?

An AI Gateway (Apigee AI Gateway / Google Cloud API Gateway's model routing) solves application/platform-layer problems — token/rate limiting, multi-model routing, centrally applying Model Armor policy. It isn't a mandatory piece:

| Condition | Recommendation |
| --- | --- |
| Single app, single team, Vertex AI only | Not needed — attach Model Armor directly to Vertex AI or the application |
| Multiple teams/apps needing unified billing and auditing | Needed — put Apigee in front as a mandatory ingress |
| Integrating third-party (non-Google) models, or need model failover | Needed — outside what Vertex AI's native mechanisms cover |
| Agentic workloads (Gemini Enterprise Agent Platform) | Evaluate Agent Gateway separately — a different product line |

## Explicitly out of scope

The following belong to the application/data team building on top of the platform, not the governance foundation:

- MLOps CI/CD pipelines, Model Registry version management, Vertex AI Model Monitoring
- Vector DB/RAG pipeline technical design, agent application logic itself
- Private Service Connect networking for Vertex AI, VPC-SC coverage of `aiplatform.googleapis.com` (extend using the existing [VPC Service Controls](/security-products/vpc-service-controls) methodology if you need it)

For MLOps/Model Registry capabilities, see Google's own [genai-mlops-blueprint](https://docs.cloud.google.com/architecture/blueprints/genai-mlops-blueprint).

Full module documentation, known limitations, and the reasoning behind each default live in [`ai-onboarding/README.md`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/ai-onboarding/README.md).
