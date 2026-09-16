---
title: Cloud Audit Logs
description: The four types of GCP audit log, and a common pitfall — Data Access audit logging is configured via IAM auditConfigs, not Organization Policy.
keywords: [Cloud Audit Logs, Admin Activity, Data Access, auditConfigs]
sidebar_position: 1
---

# 4.1 Cloud Audit Logs

GCP audit logs come in four types, and they don't all behave the same way:

| Type | Default state | Can it be disabled? | Cost |
| --- | --- | --- | --- |
| **Admin Activity** | Always on | No | Free |
| **Data Access** | **Off by default**, except for BigQuery | Yes, per service | Chargeable once enabled, and volume can be very high |
| **System Event** | Always on | No | Free |
| **Policy Denied** | Always on | No (but exclusion filters can stop it being stored) | Storage is chargeable |

:::warning
**Data Access audit logging is configured through the IAM policy's `auditConfigs`, not an Organization Policy constraint** — these are two completely different mechanisms, and it's an easy mix-up to make. Google even has a page called "[Organization Policy audit logging](https://docs.cloud.google.com/resource-manager/docs/organization-policy/audit-logging)", but that page is about how the Organization Policy Service's **own** API calls get logged — it has nothing to do with "whether to enable Data Access logs for some other service." Don't be misled by the title.
:::

To enable Data Access logging at the Organization level, you modify the Organization's IAM policy; the Terraform resource is `google_organization_iam_audit_config`, not `google_org_policy_policy` (the latter is what the [`organization-policies/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies) sub-project handles).
