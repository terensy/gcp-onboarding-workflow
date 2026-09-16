---
id: intro
title: GCP 企業級導入指南
description: 一份從 Cloud Identity 註冊、Organization 初始化、網路設計、Log 管理到安全性產品的完整 GCP 企業級導入指南，附上可直接套用的 Terraform 模組。
keywords: [GCP, Google Cloud, 企業導入, Cloud Identity, Terraform, org policy]
sidebar_position: 0
slug: /
---

# GCP 企業級導入指南

這是一份**從零開始**的 Google Cloud 企業級導入指南——從註冊 Cloud Identity、初始化 GCP Organization，到網路設計、集中式 Log 管理、安全性產品導入、Infrastructure as Code 基礎建設，涵蓋企業正式導入 GCP 時會依序遇到的每一個治理決策。

每個章節都：

- **有官方文件出處**：內容根據 Google Cloud 官方文件（Architecture Center、Security Foundations Blueprint、各產品文件）撰寫，重要結論都附上原始連結，不是憑印象寫的。
- **附可套用的 Terraform**：涉及實作的章節，連到 [GitHub repo](https://github.com/terensy/gcp-onboarding-workflow) 裡對應的 Terraform 子專案，可以直接 `terraform init/plan/apply`。
- **講決策取捨，不是只列步驟**：每個章節除了「怎麼做」，也講「為什麼」跟「不這樣做會怎樣」——這是一份給實際要做決策的人看的指南，不是操作手冊。

## 這份指南適合誰

- 第一次要幫公司導入企業級 GCP 環境的雲端工程師 / SRE
- 需要跟客戶說明 GCP 治理架構、Terraform 自動化方案的顧問
- 想知道「除了功能能動，還有哪些治理護欄該設」的技術主管

## 開始閱讀

從 [1. Cloud Identity 註冊](/cloud-identity/verify-domain) 開始，或直接跳到你現在卡住的章節：

- [2. Organization 初始化](/organization-setup/folders-projects)：Folder/Project 階層、Organization Policies、Billing、IAM
- [3. GCP 網路設計](/network-design/architecture)：Shared VPC、混合雲連線、Firewall
- [4. Log 管理](/logging/audit-logs)：Cloud Audit Logs、集中式 Log Sink
- [5. 安全性相關產品](/security-products/scc)：SCC、VPC-SC、KMS、Secret Manager、Cloud Armor
- [6. 備份與災難復原策略](/backup-dr)
- [7. Infrastructure as Code 基礎建設](/iac-bootstrap)
- [8. 其他治理事項](/governance/tagging)：Tagging/Labeling、Support Plan

## 原始碼與 Terraform 模組

這份指南對應的完整原始碼（Terraform 模組、政策 catalog、方法論文件）都在
[github.com/terensy/gcp-onboarding-workflow](https://github.com/terensy/gcp-onboarding-workflow)，歡迎直接 clone 使用或提出 Issue。
