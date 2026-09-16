---
title: Network architecture design
description: A comparison of the 4 GCP landing zone network topology options — Shared VPC, hub-and-spoke, Private Service Connect — and the trade-offs between NCC, Peering and VPN.
keywords: [Shared VPC, hub-and-spoke, Network Connectivity Center, GCP network design]
sidebar_position: 1
---

# 3.1 Network Architecture Design

Networking is the hardest landing-zone decision to walk back later. Get an IAM role wrong and you fix it with a one-line binding change; get the network architecture wrong and you're typically re-planning CIDR ranges and firewall rules across every workload already running, possibly scheduling a midnight cutover to re-segment the network. Follow [Google's own landing-zone network design guide](https://docs.cloud.google.com/architecture/landing-zones/decide-network-design) and its decision framework — think it through before you touch anything, rather than standing up a VPC first and figuring it out later.

Google documents 4 landing-zone network topologies, ordered by how much autonomy teams get versus how centralised control is:

| Option | Approach | Best fit |
| --- | --- | --- |
| **Option 1: One Shared VPC per environment** (**Google's own default recommendation for most cases**) | The host project centrally manages the network; service projects attach to share it | You want centralised control over firewalls/routing and a simple, maintainable architecture |
| Option 2: Hub-and-spoke with a centralised network appliance (NVA) | The hub VPC runs a third-party firewall appliance; spoke-to-spoke traffic routes through the hub | Compliance requires Layer‑7 inspection, or you're locked into an existing NVA vendor contract |
| Option 3: Hub-and-spoke without an appliance | The hub only carries shared on-premises connectivity; environments stay isolated from one another | You want environments kept independent while still sharing one leased line/VPN |
| Option 4: Private Service Connect producer/consumer model | Every VPC is fully independent, exposing only specific services via PSC endpoints | Teams need full autonomy, with services communicating only through explicitly defined endpoints |

![Landing zone network architecture: one Shared VPC per environment](/img/diagrams/network-design-option1-shared-vpc.svg)

:::note
Unless you have a specific reason not to, just pick **Option 1**. Most rollouts aren't special enough to need anything else — start with the simplest option, the one Google itself says fits "most cases", rather than designing for maximum complexity from day one. Complex architecture should solve a problem you've actually hit, not prove how well the team understands the cloud.
:::

If environments do need to talk to each other (Options 2/3), there are three actual mechanisms for the hub-and-spoke connectivity itself, each with its own trade-offs:

![Hub-and-spoke topology implemented with Network Connectivity Center](/img/diagrams/network-hub-spoke-ncc.svg)

| Mechanism | Bandwidth | Spoke-to-spoke (transitive)? | Notes |
| --- | --- | --- | --- |
| **Network Connectivity Center (NCC)** | Full bandwidth | Yes | Google's current recommended approach; supports star and mesh topologies |
| VPC Network Peering | Full bandwidth | No (non-transitive) | Subject to peering connection limits — you'll hit quota at scale |
| Cloud VPN | Limited by tunnel bandwidth | Yes | Insufficient bandwidth can be addressed by stacking tunnels, but complexity and cost stack up with it |

The actual Shared VPC + hierarchical firewall policy Terraform lives in the [`network-design/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/network-design) sub-project.
