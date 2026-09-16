---
title: Infrastructure as Code 基礎建設
description: 用 Workload Identity Federation 取代 Service Account 金鑰檔案，以及 Terraform State 的版本控制與 CI/CD Bootstrap 模式。
keywords: [Terraform State, Workload Identity Federation, WIF, CI/CD, terraform-example-foundation]
sidebar_position: 7
---

# 7. Infrastructure as Code 基礎建設

前面每一章的 Terraform 子專案（[`organization-policies/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies)、[`iam-bindings/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/iam-bindings)、[`network-design/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/network-design)……）預設都是「有人在自己電腦上 `terraform apply`」。正式環境不應該停在這個階段——狀態檔放在誰的筆電上、誰的憑證能 apply、有沒有 PR review 才能 apply，這些問題都需要一個共同的 CI/CD 基礎，這正是 Google 官方參考架構 [`terraform-example-foundation`](https://github.com/terraform-google-modules/terraform-example-foundation) 的 `0-bootstrap` 階段在解決的事。

該參考架構整體分幾個階段，`0-bootstrap` 是所有後續階段的地基：

| 階段 | 內容 |
| --- | --- |
| **0-bootstrap** | Seed Project、Terraform State 用的 GCS Bucket、CI/CD Pipeline、各階段專用的 Service Account |
| 1-org | 共用 Folder（Logging、KMS、SCC 通知）與網路 Folder |
| 2-environments | Dev/Non-prod/Prod 各環境的 Folder 與對應的 KMS/Secret Project |
| 3-networks-svpc **或** 3-networks-hub-and-spoke | 擇一：Shared VPC 或 Hub-and-Spoke（對應[網路架構設計](/network-design/architecture)的決策），不是兩個都要做 |
| 4-projects | 業務單位的 Service Project，掛進 Shared VPC |

`0-bootstrap` 具體做兩件事：

1. **Terraform State 放進有版本控制的 GCS Bucket**（`versioning { enabled = true }`），而不是留在某個人的筆電本機——本機 state 遺失或衝突，是最常見、也最不該發生的 Terraform 事故。
2. **CI/CD 用 [Workload Identity Federation (WIF)](https://docs.cloud.google.com/iam/docs/workload-identity-federation) 認證，不下載 Service Account 金鑰檔案**。

:::warning
Service Account 的 JSON 金鑰檔案是長期有效的憑證，外洩了在被發現、撤銷之前都能一直用——[Google 官方最佳實務](https://docs.cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys) 列出的風險包含憑證外洩、權限提升、行為不可追溯（沒辦法證明是誰用了這把金鑰做的事）。結論原文：「避免使用者自行管理的 Service Account 金鑰，盡可能改用其他驗證方式」。GitHub Actions/GitLab CI 這類外部 CI/CD 平台，改用 WIF 讓 Pipeline 用短期、動態換發的憑證登入 GCP，從根本上不會有「金鑰檔案外洩」這個攻擊面。
:::

本專案的 CI/CD Bootstrap（State Bucket + WIF Pool）見 [`iac-bootstrap/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/iac-bootstrap) 子專案；如果要完整參照 Google 官方的多階段企業導入部署管線，直接採用 [`terraform-example-foundation`](https://github.com/terraform-google-modules/terraform-example-foundation) 會比自己從零重造更省力。
