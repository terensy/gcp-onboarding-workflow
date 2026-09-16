---
title: Aggregated log sink
description: Use an Organization-level aggregated sink to route logs from every project into a dedicated logging project, fanning out to Log Analytics, Cloud Storage and a SIEM.
keywords: [aggregated sink, log sink, logging project, SIEM]
sidebar_position: 2
---

# 4.2 Aggregated Log Sink

If every project keeps its own logs, whoever's doing the auditing has to open every single project one by one — completely unworkable once a company grows. [Google's own recommendation](https://docs.cloud.google.com/architecture/landing-zones/decide-security) is an **Organization-level aggregated sink** (`includeChildren = true`) that routes logs from the whole company into one dedicated logging project — and that project's admin access needs to be kept separate from the people who admin ordinary workload projects. The logic is simple: whoever can tamper with or disable the audit trail shouldn't be the same people being audited.

![Security Foundations Blueprint's centralised logging architecture example](/img/diagrams/security-foundations-example-logging-structure.svg)

Google's own blueprint fans logs out to three destinations at once, each serving a different purpose:

| Destination | Purpose |
| --- | --- |
| Log Analytics bucket (linked to a BigQuery dataset) | Real-time querying, ad-hoc investigation during an incident |
| Cloud Storage bucket | Long-term retention for compliance/audit needs |
| Pub/Sub topic | Forwarding to an external SIEM (Splunk, QRadar, etc.) |

The actual aggregated sink + Data Access audit config Terraform lives in the [`logging/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/logging) sub-project.
