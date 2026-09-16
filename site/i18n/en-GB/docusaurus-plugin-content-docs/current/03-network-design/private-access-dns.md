---
title: Private access and Cloud DNS
description: The difference between Private Google Access and Private Service Connect, and how to design a centralised DNS hub (DNS forwarding / DNS peering).
keywords: [Private Google Access, Private Service Connect, Cloud DNS, DNS peering, DNS forwarding]
sidebar_position: 3
---

# 3.3 Private Access & Cloud DNS

If a VM only has an internal IP (per the [`compute.vmExternalIpAccess` policy](/organization-setup/organization-policies)), how does it reach Google APIs? Two mechanisms:

- **[Private Google Access](https://docs.cloud.google.com/vpc/docs/private-google-access)**: a subnet-level switch that lets internal-IP-only instances reach Google APIs' public endpoints. Simple to set up, but doesn't support regional or multi-regional endpoints.
- **[Private Service Connect (PSC)](https://docs.cloud.google.com/vpc/docs/private-service-connect)**: creates an endpoint using an internal IP inside your own VPC, so traffic never leaves Google's network at all. [Google's own Security Foundations Blueprint](https://docs.cloud.google.com/architecture/blueprints/security-foundations/networking) currently uses exactly this — PSC combined with a private DNS zone — rather than relying on Private Google Access alone.

For Cloud DNS, in a multi-environment or multi-VPC architecture it's worth designing a **centralised DNS hub**: on-premises domains are handled via **DNS forwarding** to your on-prem DNS servers, while lookups between VPCs inside Google Cloud go through **DNS peering** (peering connections can't forward DNS queries themselves, which is exactly why a multi-VPC setup needs a dedicated DNS hub design rather than having each VPC forward independently).

![Security Foundations Blueprint's centralised DNS architecture example](/img/diagrams/security-foundations-example-dns-setup.svg)
