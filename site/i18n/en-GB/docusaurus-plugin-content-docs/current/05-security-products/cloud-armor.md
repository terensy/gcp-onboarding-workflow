---
title: Cloud Armor
description: Cloud Armor's WAF and DDoS protection, the OWASP Core Rule Set, rate limiting, and the Enterprise tier's hierarchical security policies.
keywords: [Cloud Armor, WAF, DDoS, OWASP Core Rule Set, rate limiting]
sidebar_position: 5
---

# 5.5 Cloud Armor

[WAF and DDoS protection](https://docs.cloud.google.com/armor/docs/cloud-armor-overview) sitting in front of your load balancer.

![Where Cloud Armor enforces at the network edge](/img/diagrams/cloud-armor-edge-enforcement.svg)

L3/L4 DDoS protection is automatic, free, and requires no configuration; L7 protection (against things like HTTP floods) needs a security policy configured separately — you can apply the OWASP Core Rule Set as a default WAF ruleset (with sensitivity levels 0–4; higher sensitivity catches more but also false-positives more against legitimate traffic), and configure rate limiting. The paid Enterprise tier adds Adaptive Protection (ML-based attack-pattern detection), threat intelligence feeds, and **hierarchical security policies** — letting you set a baseline at the Org/Folder level that individual projects then layer their own rules on top of.
