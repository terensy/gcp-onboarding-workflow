---
title: Hybrid connectivity
description: Comparing Cloud VPN, Dedicated Interconnect, Partner Interconnect and Cross-Cloud Interconnect on bandwidth, SLA and best-fit scenarios.
keywords: [Cloud VPN, Dedicated Interconnect, Partner Interconnect, Cross-Cloud Interconnect, hybrid cloud]
sidebar_position: 2
---

# 3.2 Hybrid Connectivity

Enterprises adopting GCP almost always go through a period of "on-premises plus cloud" coexistence, so how you pick the line back to your own data centre matters. [Google's own comparison](https://docs.cloud.google.com/network-connectivity/docs/how-to/choose-product) boils the decision down to something simple:

| Option | Bandwidth | SLA | Best fit |
| --- | --- | --- | --- |
| **Cloud VPN (HA VPN)** | Limited by tunnel count, lower bandwidth | 99.99% (dual-interface) / 99.9% | Cost-sensitive, low bandwidth needs, or still evaluating |
| **Dedicated Interconnect** | 10 / 100 / 400 Gbps | Google provides an end-to-end SLA directly | Enterprise-grade, needs the highest throughput, and you can arrange colocation yourself |
| **Partner Interconnect** | 50 Mbps – 50 Gbps, flexible | Provided by the service provider | Enterprise-grade connectivity without a colocation presence |
| **Cross-Cloud Interconnect** | Depends on the target cloud (up to 400 Gbps for AWS/OCI) | 99.99% (cross-facility) / 99.9% | Direct connectivity to another public cloud (AWS/Azure/OCI/Alibaba), bypassing the public internet |

:::tip
The general rule: start cheap with Cloud VPN, and only move to Interconnect once you genuinely need the throughput and can commit to a colocation arrangement. Don't let a sales conversation talk you into an expensive Dedicated Interconnect contract before your actual usage is anywhere near it.
:::
