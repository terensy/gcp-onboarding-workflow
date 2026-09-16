---
title: Google Cloud Support Plan
description: Comparing the cost, P1 response time and TAM coverage of the Basic/Standard/Enhanced/Premium Support Plan tiers, and which tier production actually needs.
keywords: [Google Cloud Support, Support Plan, TAM, P1 SLA]
sidebar_position: 2
---

# 8.2 Google Cloud Support Plan

| Tier | Cost (USD) | P1 (critical incident) response time | 24/7 coverage | Dedicated TAM |
| --- | --- | --- | --- | --- |
| Basic | Free | No case support | No | No |
| Standard | $29/month or 3% of monthly spend, whichever is higher | **Not offered** (P1 as a severity level doesn't exist under Standard) | No, business hours only | No |
| Enhanced | From $100/month, percentage tapers with spend | 1 hour | Yes (for high/critical-impact incidents) | No (a paid Technical Account Advisor add-on is available) |
| Premium | From $15,000/month, percentage tapers with spend | **15 minutes** | Yes | Yes, a named dedicated TAM |

:::danger
Standard tier has **no P1 severity level at all** — it's not "a slower response", it's that this class of incident doesn't exist in the Standard contract at all. Choosing a Support Plan purely on "is there a local-language contact" and "how cheap is it" and landing on Standard means finding out, the night production goes down, that opening a case only gets you business-hours coverage — and an outage of this severity isn't even in Standard's scope to begin with. **Enhanced is the floor for anything running in production** (that's exactly how Google itself positions it); Premium is the one with the 15-minute SLA and a dedicated TAM, reserved for genuinely mission-critical services where a minute of downtime means real money lost.
:::
