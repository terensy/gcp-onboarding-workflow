---
title: Cloud NAT
description: Once external IPs are disabled on VMs, use Google's fully managed, distributed Cloud NAT to keep outbound internet access for package updates working.
keywords: [Cloud NAT, GCP outbound access, distributed NAT]
sidebar_position: 4
---

# 3.4 Cloud NAT

Once the `compute.vmExternalIpAccess` policy (see [Organization Policies](/organization-setup/organization-policies)) disables external IPs on VMs, how do they reach the outside world to download package updates? The answer is [Cloud NAT](https://docs.cloud.google.com/nat/docs/overview) — a fully managed, distributed NAT service from Google, not a single NAT VM acting as a point of failure. You just open a gateway in each region that needs outbound access, and set logging to at least `ERRORS_ONLY` so failed connections are easy to investigate afterwards.
