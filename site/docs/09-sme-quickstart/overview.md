---
title: 中小企業快速佈建
description: 給第一次導入 GCP 的中小型企業用的精簡版 Terraform，一次 apply 佈出 Folder/Project、Organization Policies 子集、IAM、Shared VPC、集中稽核 Logging，並保留升級到企業版架構的路徑。
keywords: [SME, SMB, 中小企業, GCP quickstart, Terraform, Shared VPC, HA VPN]
sidebar_position: 1
---

# 9. 中小企業快速佈建（SME Quickstart）

前面幾章是**完整的企業級導入流程**，涵蓋多環境、完整 CIS 合規政策等大型企業才需要的複雜度。如果貴公司只需要一套「不做會出事、做了成本可控」的最小可用架構，可以直接用 [`sme-quickstart/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/sme-quickstart)——精簡版 Terraform，一次 `terraform apply` 佈出基本治理架構，且升級路徑直接沿用前面各章節的企業版 Terraform 子專案，不需要重寫架構。

## 有做什麼、沒做什麼

| 章節 | 有做 | 沒做（之後有需要再加） |
| --- | --- | --- |
| [Folder/Project](/organization-setup/folders-projects) | 兩個 Folder：`network`（Shared VPC Host Project）、`service`（Workload Project）；集中稽核用的 Logging Project 直接掛 Organization | 多環境（dev/nonprod/prod）或子公司分層 |
| [Organization Policies](/organization-setup/organization-policies) | 精選 8 條投報率最高的政策（禁對外分享網域、禁 SA 金鑰、禁 VM 外部 IP、禁預設網路、強制 OS Login、Bucket 統一層級存取、限制 SQL 對外 IP、限制資源地區） | 完整 33 條 CIS Benchmark catalog |
| [IAM](/organization-setup/iam-bindings) | 5 個最小必要管理群組，綁在 Organization/Billing 層級 | （本來就輕量，跟企業版一致） |
| [網路](/network-design/architecture) | Shared VPC + 階層式防火牆基準線 | [混合雲連線](/network-design/hybrid-connectivity)預設關閉，見下方「可選：VPN」 |
| [Logging](/logging/aggregated-sink) | 獨立 Logging Project + Organization 層級 Aggregated Sink，只開 Cloud Storage 歸檔 | Log Analytics（BigQuery 即時查詢）、Pub/Sub 轉 SIEM、[Data Access Audit Log](/logging/audit-logs) |
| [安全性產品](/security-products/scc) | 無 | SCC、VPC-SC、CMEK、Secret Manager、Cloud Armor、Binary Authorization，等真的有需求再導入 |
| [備份 DR](/backup-dr) | 無 | 用 Cloud SQL/Persistent Disk 原生備份機制即可 |
| [IAC Bootstrap](/iac-bootstrap) | 建議先做 | — |

## Folder 結構

```
Organization
├── Folder: network      → Shared VPC Host Project（之後 VPN 也在這裡）
├── Folder: service       → Workload/Service Project
└── Project: logging      → 直接掛 Organization，不放進任何 Folder
```

Logging Project 刻意不放進 `network` 或 `service` Folder——能查/改稽核紀錄的人，不該跟管網路或管服務的人是同一群人，直接掛 Organization 讓管理權限的邊界最乾淨。

## 可選：VPN（混合雲連線）

沒有地端機房要接的話，完全忽略這段即可——`enable_vpn` 預設 `false`，`terraform plan` 不會產生任何 VPN 相關資源。

確定要接地端網路時：

1. 跟地端網路團隊先對好：地端設備的 ASN、對外公開 IP（1 個或 2 個）、BGP link-local IP 區段、IKE 共用金鑰。
2. 打開 `enable_vpn = true`，填入對端資訊（見 repo 內的 [`terraform.tfvars.example`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/sme-quickstart/examples/root/terraform.tfvars.example)）。
3. 共用金鑰**不要**寫進 `terraform.tfvars`，改用環境變數帶入。

技術細節（HA VPN + Cloud Router BGP、SLA 等級）見[混合雲連線](/network-design/hybrid-connectivity)。Dedicated/Partner/Cross-Cloud Interconnect 需要走實體線路申請流程，這裡沒有對應 module。

:::tip
這是 **MVP**，不是終態。企業成長到需要更細緻的治理時，直接切換去用完整的企業版 Terraform 子專案即可——SME 版本本來就是直接引用它們，沒有另外複製一份邏輯，升級不需要重新設計架構。
:::

## 開始使用

```bash
cd sme-quickstart/examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：org_id、domain、billing_account_id、
# host_project_id、service_project_ids、logging_project_id、subnets

terraform init
terraform plan
terraform apply
```

完整的前置作業、套用帳號需要的權限、已知限制，見 repo 內的 [`sme-quickstart/README.md`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/sme-quickstart)。
