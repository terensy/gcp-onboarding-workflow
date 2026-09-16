---
title: Firewall management
description: The differences between hierarchical firewall policies, network firewall policies and legacy VPC firewall rules, and designing a baseline rule set for micro-segmentation.
keywords: [hierarchical firewall policy, network firewall policy, VPC firewall rules, micro-segmentation]
sidebar_position: 5
---

# 3.5 Firewall Management

Firewall rules aren't a single mechanism — Google currently offers three layers, each with a different scope and precedence:

| Mechanism | Scope | Characteristics |
| --- | --- | --- |
| **Hierarchical firewall policy** | Attached to the Organization or a Folder, inherited down to every project | **Lower-level rules can never override a higher-level rule** — put your company-wide security baseline here, and one change applies everywhere |
| **Network firewall policy** (global/regional) | Attached to one or more VPCs | Each VPC's own rules, for needs specific to that network |
| VPC firewall rules (legacy mode) | A single VPC | The oldest mechanism — Google's own Security Foundations Blueprint **no longer uses it**, relying on the two layers above instead |

![Security Foundations Blueprint's layered firewall rules example](/img/diagrams/security-foundations-example-firewall-rules.svg)

Google's own blueprint approach: attach a hierarchical firewall policy to every folder, covering RFC 1918 internal traffic, [IAP TCP forwarding](https://docs.cloud.google.com/iap/docs/using-tcp-forwarding) (`35.235.240.0/20`), and Load Balancer health-check source ranges (`35.191.0.0/16`, `130.211.0.0/22`) — these are the **baseline rules every company needs allowed**. Rules specific to an individual VPC are then layered on separately via a network firewall policy. The guiding principle is one sentence: **deny everything by default, and open only the traffic you actually need** (micro-segmentation) — not the other way round, starting wide open and patching holes as you go.

The actual hierarchical firewall policy Terraform lives in the [`network-design/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/network-design) sub-project.
