---
title: Cloud Audit Logs
description: GCP 稽核紀錄的四種類型，以及一個常見誤區：Data Access 稽核紀錄是用 IAM auditConfigs 設定，不是 Organization Policy。
keywords: [Cloud Audit Logs, Admin Activity, Data Access, auditConfigs]
sidebar_position: 1
---

# 4.1 Cloud Audit Logs

GCP 的稽核紀錄分四種，行為都不一樣：

| 類型 | 預設狀態 | 能關掉嗎 | 費用 |
| --- | --- | --- | --- |
| **Admin Activity** | 一律開啟 | 不行 | 免費 |
| **Data Access** | 除了 BigQuery 以外**預設關閉** | 可以，依服務個別開關 | 開了要收費，且資料量可能非常大 |
| **System Event** | 一律開啟 | 不行 | 免費 |
| **Policy Denied** | 一律開啟 | 不行（但可設 exclusion filter 不存） | 儲存要收費 |

:::warning
**Data Access 稽核紀錄是用 IAM Policy 的 `auditConfigs` 設定，不是 Organization Policy constraint**——這兩個是完全不同的機制，很容易搞混。Google 甚至有一個叫「[Organization Policy audit logging](https://docs.cloud.google.com/resource-manager/docs/organization-policy/audit-logging)」的頁面，但那是在講 Organization Policy Service **自己的** API 呼叫怎麼被記錄，跟「要不要開啟其他服務的 Data Access log」完全是兩回事，別被標題騙了。
:::

要在 Organization 層級開啟 Data Access log，是修改 Organization 的 IAM Policy，Terraform 對應的資源是 `google_organization_iam_audit_config`，不是 `google_org_policy_policy`（後者是 [`organization-policies/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies) 子專案在處理的東西）。
