---
title: IAM role bindings
description: Bind your admin groups to actual GCP IAM roles — least privilege, predefined roles, group-based inheritance, Deny policies and PAM.
keywords: [GCP IAM, IAM binding, least privilege, predefined role, IAM Deny]
sidebar_position: 4
---

# 2.4 IAM Role Bindings

This is where the 5 groups created in [Decide Your User Source & Build Groups](/cloud-identity/user-groups) actually get "cashed in" as real permissions. [Google's IAM security best practices](https://cloud.google.com/iam/docs/using-iam-securely) put it plainly:

:::info
Unless you genuinely have no alternative, don't grant basic roles (Owner / Editor / Viewer) in production. Prefer Google-maintained predefined roles, and bind roles to **groups**, not individual accounts — [Google's own Enterprise Foundations Blueprint](https://cloud.google.com/architecture/blueprints/security-foundations/authentication-authorization) uses exactly this "group by job function, bind roles to groups" pattern.
:::

![IAM policy inheritance down the resource hierarchy](/img/diagrams/iam-policy-inheritance.svg)

IAM policy is **inherited** down the hierarchy — Organization → Folder → Project → resource — and only ever adds up, never gets narrowed by a lower level: a role granted at the Organization level automatically applies to every folder and project beneath it. That has two implications:

1. The higher up the hierarchy a role is bound, the larger its blast radius and the higher the cost of a mistake — which is exactly why binding all 5 groups at the Organization level was a deliberate choice, not an oversight.
2. You shouldn't (and don't need to) re-grant the same role manually in every project — if you find yourself setting the same role in dozens of projects one at a time, that's a sign your group and hierarchy planning has a gap, and the fix is to revisit [folder planning](/organization-setup/folders-projects), not to keep piling on manual bindings.

The actual bindings are done with the Terraform module in [`iam-bindings/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/iam-bindings), which reads `bindings_catalog.yaml` and binds the 5 groups directly to their corresponding roles. The module handles both Organization-level and billing-account-level bindings separately.

:::tip
Beyond long-lived bindings, [Privileged Access Manager (PAM)](https://cloud.google.com/iam/docs/pam-overview) supports "just-in-time elevation, automatically revoked when you're done." For high-risk roles like Organization Administrator, a more rigorous approach is to grant no standing access at all — request a time-bound PAM grant when the work actually needs doing, and let it expire automatically rather than relying on someone remembering to revoke it.
:::

:::danger
"Just give everyone Owner for now, we'll tighten it up later" is a common and dangerous shortcut — that "later" tends to never arrive, because permissions only ever get more generous: hardly anyone volunteers to claw back access that's already in use, for fear of breaking something. By the time an actual security incident forces you to answer "who could touch this database", you find half the org is Owner, and the audit tells you nothing. The structural fix is an [IAM Deny policy](https://cloud.google.com/iam/docs/deny-overview) that explicitly blocks basic roles (Deny always outranks any Allow, no exceptions) — so you never leave "we'll tighten it up later" as an option in the first place.
:::
