---
title: Resource tagging and labelling strategy
description: The real difference between Labels and Tags — and why only Tags can be used in IAM and Organization Policy conditions.
keywords: [GCP Labels, GCP Tags, resource tagging, conditional policy]
sidebar_position: 1
---

# 8.1 Resource Tagging / Labelling Strategy

Labels and Tags are two different mechanisms — a lot of people assume they're just two names for the same thing:

| | Labels | Tags |
| --- | --- | --- |
| What they are | Key-value **metadata** attached to a resource | Independent GCP **resource objects** (the Tag Key/Value must be created first) |
| Usable in IAM / Org Policy conditions? | **No** | **Yes** — e.g. "only apply this policy to resources tagged `env:prod`" |
| Inherited by child resources? | No | Yes, by default |
| Main use | Cost categorisation, resource inventory (flows into Billing Export — see [Billing Account Setup & Governance](/organization-setup/billing)) | Conditional access control / policy scoping |

[Google's own recommendation](https://docs.cloud.google.com/resource-manager/docs/best-practices-labels) for common label keys: `environment`, `cost-center`, `team`, `component`, `application`, `compliance` — and **keep it to under 10**, since beyond that the operational overhead outweighs the value. One more thing Google is explicit about: **never put PII or any sensitive information in a label** — it isn't a field designed for protected/encrypted storage.

A common trap in practice: Tags can be used in an IAM Deny policy or an Organization Policy condition (e.g. "only block resources that don't carry the `sqlAdmin:enabled` tag from using this API"), but Labels can't do this at all. If a "conditional" governance requirement won't configure no matter what you try, check whether you've mixed the two up — you may need Tags where you've reached for Labels instead.
