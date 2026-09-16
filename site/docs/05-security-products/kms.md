---
title: Cloud KMS（CMEK）
description: 何時需要 Customer-Managed Encryption Keys、三種金鑰保護等級的成本差異，以及用 Organization Policy 強制 CMEK 的方式。
keywords: [Cloud KMS, CMEK, Customer-Managed Encryption Keys, HSM]
sidebar_position: 3
---

# 5.3 Cloud KMS（CMEK）

GCP 預設用 Google 自己管理的金鑰加密所有靜態資料，客戶看不到、也管不了這把金鑰。如果法遵要求客戶自己掌控金鑰的生命週期（輪替排程、誰能用、事後稽核），才需要 [CMEK](https://docs.cloud.google.com/kms/docs/cmek)（Customer-Managed Encryption Keys）——這是合規要求時才加開的選項，不是每個資源都需要的預設值。

金鑰有三種保護等級，成本差很多：Software（多數 Region 都有，最便宜）、Cloud HSM（FIPS 140-2 Level 3，專用硬體）、Cloud EKM（金鑰留在外部 KMS，Google 完全碰不到，但輪替要手動跟外部系統協調）。

:::note
輪替金鑰**不會**自動重新加密已經加密過的舊資料，舊的金鑰版本也不會自動失效——舊版本要留著才能解開舊資料，真的要汰換要另外手動處理。這點常被誤會成「輪替等於舊金鑰立刻作廢」。
:::

要強制特定服務必須用 CMEK，是用 Organization Policy 的 `constraints/gcp.restrictNonCmekServices`（禁止建立非 CMEK 保護的資源）搭配 `constraints/gcp.restrictCmekCryptoKeyProjects`（限制金鑰只能來自指定的 KMS Project）——這兩條可以照 [organization-policies 方法論](https://github.com/terensy/gcp-onboarding-workflow/blob/main/organization-policies/docs/methodology.md) 評估後加進該子專案的 catalog。
