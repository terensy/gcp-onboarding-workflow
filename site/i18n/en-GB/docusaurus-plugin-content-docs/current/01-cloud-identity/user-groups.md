---
title: Decide your user source and build groups
description: Decide whether GCP user accounts should come from an existing Identity Provider or from Cloud Identity, then plan the minimum viable set of admin groups.
keywords: [Cloud Identity, IdP, SSO, group planning, IAM groups]
sidebar_position: 2
---

# 1.2 Decide Your User Source & Build Groups

## User source

Most companies already run an Identity Provider (IdP) — and Cloud Identity is itself a kind of IdP. So before letting anyone inside the company use GCP, decide whether user accounts should originate from your existing IdP or be created directly in Cloud Identity.

- If you're creating accounts directly in Cloud Identity, build your groups and users straight in the Cloud Identity console.
- If you're using an existing IdP, follow Google's and your IdP's official documentation to set up sync and federated sign-on.

:::tip
[SOP for provisioning users/groups from Entra ID into Google Cloud Identity and setting up SSO](https://github.com/terensy/entraid-cloudidentity-provisioning-sso-sop.git)
:::

## Group planning

Whether on-premises or in the cloud, managing access through groups is standard practice — it's far more efficient and logical than managing each user's roles and permissions individually. So once you've decided where your users come from, plan your groups. You can base this on [Google's own group-planning example](https://docs.cloud.google.com/architecture/blueprints/security-foundations/authentication-authorization?hl=en#groups_for_access_control), or on however your other systems already divide up groups.

Before you get into detailed group design, build at least these **minimum viable admin groups** first, since later chapters bind IAM roles to them directly:

| Group (example naming) | Purpose | Typical GCP IAM role |
| --- | --- | --- |
| gcp-organization-admins@ | Manage Organization-level settings and the folder/project hierarchy | Organization Administrator |
| gcp-billing-admins@ | Manage the billing account, budgets and cost control | Billing Account Administrator |
| gcp-network-admins@ | Manage shared networking (Shared VPC), firewalls, hybrid connectivity | Network Admin, Compute Network Admin |
| gcp-security-admins@ | Manage Organization Policy, IAM auditing, Security Command Center | Organization Policy Administrator, Security Admin |
| gcp-logging-admins@ | Manage the centralised log sink, audit trails, monitoring alerts | Logs Configuration Writer, Monitoring Admin |

Once these groups exist, add only the small number of people handling the initial setup (e.g. the current super admin, or the IT lead). Once [IAM role bindings](/organization-setup/iam-bindings) are done, adjust membership to match the real owners; after that, remove the super admin from day-to-day use entirely, keeping it strictly within the scope of the [break-glass emergency access accounts](/cloud-identity/verify-domain) to reduce the daily exposure of your highest-privilege account.

:::info
Whether it's GCP, AWS, Azure or any other public cloud, the right approach is to learn the fundamentals first, then map that back onto your own company's organisational structure and system-administration hierarchy — that's what makes group planning effective. Remember: nobody understands your company better than you do. Don't hand user and group planning to a vendor from day one; draft your own first version, then seek best-practice input.
:::

:::info
Users and groups created in Cloud Identity can have permissions configured, but those permissions control access to Cloud Identity — the IdP itself — and other Google services. They are **not** GCP permissions. GCP access is configured separately, in the GCP IAM console.
:::
