---
title: 資源 Tagging / Labeling 策略
description: Labels 與 Tags 的本質差異——為什麼只有 Tags 能用在 IAM 與 Organization Policy 的條件式判斷。
keywords: [GCP Labels, GCP Tags, resource tagging, 條件式政策]
sidebar_position: 1
---

# 8.1 資源 Tagging / Labeling 策略

Labels 跟 Tags 是兩個不同的機制，很多人以為是同一件事的兩種說法：

| | Labels | Tags |
| --- | --- | --- |
| 本質 | Key-Value **中繼資料**，掛在資源上 | 獨立的 GCP **資源物件**（Tag Key/Value 本身要先建立） |
| 能否用在 IAM / Org Policy 條件式判斷 | **不行** | **可以**——例如「只有掛了 `env:prod` 標籤的資源才套用某條政策」 |
| 是否會被子資源繼承 | 不會 | 預設會繼承到底下的資源 |
| 主要用途 | 成本分類、資源盤點（會被帶進 Billing Export，見 [Billing 帳戶設定與治理](/organization-setup/billing)） | 條件式的存取控制／政策範圍 |

[Google 官方建議](https://docs.cloud.google.com/resource-manager/docs/best-practices-labels) 的常見 Label key：`environment`、`cost-center`、`team`、`component`、`application`、`compliance`，且**不要超過 10 個**，多了維運成本比帶來的價值還高。官方另外特別提醒：**Label 不要放 PII 或任何敏感資訊**，它不是拿來加密保護的欄位。

實務上的地雷：Tag 可以拿來當 IAM Deny 政策或 Organization Policy 的條件式判斷（例如「只擋掉沒有 `sqlAdmin:enabled` 標籤的資源使用某個 API」），但 Label 完全不行——如果發現某個「條件式」的治理需求怎麼設都設不出來，先檢查是不是搞混了兩者，該用 Tags 卻用成了 Labels。
