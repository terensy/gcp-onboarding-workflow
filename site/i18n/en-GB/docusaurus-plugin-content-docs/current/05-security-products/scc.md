---
title: Security Command Center (SCC)
description: Comparing SCC's Standard, Premium and Enterprise tiers, and why it's worth activating at the Organization level.
keywords: [Security Command Center, SCC, Security Health Analytics, Event Threat Detection]
sidebar_position: 1
---

# 5.1 Security Command Center (SCC)

A centralised security-risk dashboard: asset inventory, [misconfiguration detection (Security Health Analytics)](https://docs.cloud.google.com/security-command-center/docs/concepts-security-health-analytics), vulnerability scanning, [threat detection (Event Threat Detection)](https://docs.cloud.google.com/security-command-center/docs/concepts-event-threat-detection-overview), and compliance-posture mapping (CIS/NIST/HIPAA/PCI-DSS) — all in one place.

![Core security services used by the Security Foundations Blueprint](/img/diagrams/security-foundations-key-services.svg)

| Tier | Cost | Coverage |
| --- | --- | --- |
| **Standard** | Free | Basic misconfiguration/threat detection, GCP only |
| **Premium** | Paid (usage-based or subscription) | Full Security Health Analytics, vulnerability assessment (including AWS scanning), full threat detection, compliance mapping, Attack Path Simulation |
| Enterprise | Paid | Multi-cloud CNAPP, SIEM/SOAR integration — Google has announced this tier will be discontinued on 21 May 2027 and merged into Premium, so it's not worth choosing for a new rollout |

[Google recommends activating SCC at the Organization level](https://docs.cloud.google.com/security-command-center/docs/activate-scc-overview) so it covers every folder and project beneath it in one go, rather than each project activating it separately and each ending up with its own blind spots. Findings can be forwarded via Pub/Sub to an existing SIEM/SOAR (Splunk, QRadar, Google SecOps, etc.).
