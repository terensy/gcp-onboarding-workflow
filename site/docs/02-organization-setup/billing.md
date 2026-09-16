---
title: Billing 帳戶設定與治理
description: Cloud Billing 帳戶結構、角色分工、預算告警、Billing Export to BigQuery，以及常見的成本治理誤區。
keywords: [Cloud Billing, GCP 帳單, Billing Account Administrator, Budgets and alerts]
sidebar_position: 3
---

# 2.3 Billing 帳戶設定與治理

Billing 帳戶是獨立於 Organization / Folder / Project 之外的另一個資源階層——這是最多人搞混的地方，很多人直覺以為 Billing 權限也是在 Organization IAM 那邊設定，結果找半天找不到，其實要去 Billing 帳戶自己的 IAM 頁籤設定。

[Google 官方 Billing 導入檢查清單](https://cloud.google.com/billing/docs/onboarding-checklist) 建議：

:::tip
建立單一、集中的 Cloud Billing 帳戶掛在 Organization 底下就好，除非有法遵/會計分帳、幣別、或需要分開請款等具體理由，才需要拆成多個 Billing 帳戶。
:::

![Billing 帳戶的 ownership 與 payment linkage 關係](/img/diagrams/billing-access-control-org.png)

## 角色分工

| 角色 | 可以做什麼 | 給誰 |
| --- | --- | --- |
| **Billing Account Administrator**（`roles/billing.admin`） | 管理付款方式、啟用 Billing Export、設定預算告警、**連結/解除連結專案**、管理其他人在這個 Billing 帳戶上的角色 | `gcp-billing-admins@`，通常是真正對損益負責的財務/IT 主管 |
| Billing Account User | 可以把專案**連結**到 Billing 帳戶，但不能解除連結 | 需要自助建立專案的團隊，搭配 Project Creator 角色 |
| Project Billing Manager（Project 層級角色） | 只能把自己有權限的專案，連去自己有 User 角色的 Billing 帳戶，對專案內資源沒有任何存取權 | 想讓團隊自助掛帳，又不想給完整 Billing 帳戶權限時使用 |

:::info
Billing Account Administrator 的權限要綁在 Billing 帳戶本身（Terraform 資源是 `google_billing_account_iam_member`），不是 Organization——這兩個是獨立的資源階層，詳見 [`iam-bindings/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/iam-bindings) 子專案。
:::

## 預算與告警

在 Billing 帳戶的「**Budgets & alerts**」設定預算，可以用實際花費或**預測花費**當觸發條件，預設門檻是 50% / 90% / 100%。告警除了寄信給 Billing Admin，也可以接 Pub/Sub 做自動化（例如超過門檻就自動停用某個測試專案的 Billing，避免忘記關的資源燒一整個月的錢）。

:::danger
「Alerts only」的預算**不會**自動幫你把服務停掉或設用量上限，它只是寄信通知。這點很多人都會誤會，覺得設了預算等於有一個天花板，結果帳單照樣爆表，月底檢討會上才問「為什麼設了預算還是超支」。設預算只是讓你早一點發現問題，不是幫你踩剎車，真的要有用量上限，需要另外接 Pub/Sub 自動化去停用/降級資源。
:::

## Billing Export to BigQuery

建議專案初期就開啟 [Billing Export to BigQuery](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)（至少開 Standard usage cost data，有明細分析需求再加開 Detailed usage cost data），因為 **Export 只會從開啟的當下開始收資料，沒辦法回溯**——很多團隊都是帳單已經出問題了才想到要開 Export，結果發現分析不了「過去」發生了什麼事，只能眼睜睜看著同樣的問題下個月再發生一次。

## 成本歸屬

透過 [Labels](https://cloud.google.com/resource-manager/docs/labels-overview) 標記 `environment`、`cost-center`、`team` 等 key-value，Labels 會被帶進 Billing Export，可以回答「這個月 Database 花了多少錢」這類問題。完整的標籤治理策略見 [8.1 資源 Tagging / Labeling 策略](/governance/tagging)。
