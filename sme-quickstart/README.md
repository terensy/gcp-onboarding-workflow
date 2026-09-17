# SMB 快速佈建（SME Quickstart）

給**第一次導入 GCP 的中小型企業**用的精簡版 Terraform，一次 `terraform apply` 佈出一套基本可用的治理架構。對應最外層 [README.md](../README.md) 的完整企業級導入流程，但砍掉多環境/多子公司這類大型企業才需要的複雜度，只留下「不做會出事、做了成本可控」的最小必要子集。

> [!IMPORTANT]
> 這是 **MVP**，不是終態。企業成長到需要更細緻的治理（多環境 Folder、完整 CIS 政策、VPC-SC、CMEK、Backup and DR Service……）時，直接切換去用 [organization-policies/](../organization-policies/)、[network-design/](../network-design/)、[security-products/](../security-products/) 這些企業版子專案即可——這份 SME 版本本來就是直接引用它們的 module，沒有另外複製一份邏輯，升級路徑不需要重寫架構。

## 這份快速佈建做了什麼、沒做什麼

| 章節 | 有做 | 沒做（Phase 2 再考慮） |
|---|---|---|
| Folder/Project | 兩個 Folder：`network`（Shared VPC Host Project）、`service`（Workload Project）；集中稽核用的 Logging Project 直接掛 Organization | 多環境（dev/nonprod/prod）或子公司分層 |
| Organization Policies | 精選 8 條投報率最高的政策（禁對外分享網域、禁 SA 金鑰、禁 VM 外部 IP、禁預設網路、強制 OS Login、Bucket 統一層級存取、限制 SQL 對外 IP、限制資源地區） | 完整 35 條 catalog（含 CIS Benchmark 與 AI/Vertex AI 專屬延伸建議） |
| IAM | 5 個最小必要管理群組，綁在 Organization/Billing 層級 | （本來就輕量，跟企業版一致） |
| 網路 | Shared VPC + 階層式防火牆基準線（IAP/健康檢查/RFC1918/預設擋） | 混合雲連線預設關閉，見下方「可選：VPN」 |
| Logging | 獨立 Logging Project + Organization 層級 Aggregated Sink，只開 Cloud Storage 歸檔 | Log Analytics（BigQuery 即時查詢）、Pub/Sub 轉 SIEM、Data Access Audit Log |
| 安全性產品 | 無 | Security Command Center、VPC-SC、CMEK、Secret Manager、Cloud Armor、Binary Authorization——見 [security-products/](../security-products/)，等真的有需求再導入 |
| 備份 DR | 無 | 用 Cloud SQL/Persistent Disk 原生備份機制即可，見最外層 README.md 6.1 節 |
| IAC Bootstrap | 建議先做，見 [iac-bootstrap/](../iac-bootstrap/) | — |

## 目錄結構

```
.
├── modules/
│   └── resource_hierarchy/   # network/service Folder + Host/Service/Logging Project
└── examples/root/            # 把下面 6 個 module 組合成一次 apply 的完整範例
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars.example
    └── versions.tf
```

`examples/root` 實際引用的 module，全部是既有子專案、沒有重造：

1. `modules/resource_hierarchy`（本專案新增）
2. `../../organization-policies/modules/org_policies`
3. `../../iam-bindings/modules/iam_bindings`
4. `../../network-design/modules/shared_vpc`
5. `../../network-design/modules/hierarchical_firewall`
6. `../../network-design/modules/cloud_vpn`（選用，見下方）
7. `../../logging/modules/aggregated_logging`

## 為什麼 Folder 這樣分

```
Organization
├── Folder: network      → Shared VPC Host Project（之後 VPN 也在這裡）
├── Folder: service       → Workload/Service Project
└── Project: logging      → 直接掛 Organization，不放進任何 Folder
```

Logging Project 刻意不放進 `network` 或 `service` Folder——能查/改稽核紀錄的人，不該跟管網路或管服務的人是同一群人，直接掛 Organization 讓 `gcp-logging-admins@` 的權限邊界最乾淨（詳見 [logging/modules/aggregated_logging/variables.tf](../logging/modules/aggregated_logging/variables.tf) 對 `logging_project_id` 的說明）。

## 快速開始

前置作業（Terraform 管不到，必須先手動完成，見最外層 README.md 1、2.3 節）：

1. 用 Domain name 註冊 Cloud Identity、設定超級管理員兩步驟驗證、建立 [5 個最小必要管理群組](../README.md#12-決定-user-來源--建立群組與人員)。
2. 取得或建立 Cloud Billing 帳戶。
3. 套用帳號至少要有：`roles/resourcemanager.organizationAdmin`、`roles/orgpolicy.policyAdmin`、`roles/billing.admin`、`roles/compute.xpnAdmin`、`roles/compute.securityAdmin`、`roles/logging.configWriter`。

```bash
cd examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：org_id、domain、billing_account_id、
# host_project_id、service_project_ids、logging_project_id、subnets

terraform init
terraform plan
terraform apply
```

> [!TIP]
> 正式環境建議先完成 [iac-bootstrap/](../iac-bootstrap/) 拿到 State GCS Bucket + WIF，把這裡的 `apply` 改走 CI/CD，不要留在個人電腦上執行，見最外層 README.md 7 章。

## 可選：VPN（混合雲連線）

沒有地端機房要接的話，完全忽略這段即可——`enable_vpn` 預設 `false`，`terraform plan` 不會產生任何 VPN 相關資源。

確定要接地端網路時：

1. 跟地端網路團隊先對好：地端設備的 ASN、對外公開 IP（1 個或 2 個）、BGP link-local IP 區段、IKE 共用金鑰。
2. 在 `terraform.tfvars` 打開 `enable_vpn = true`，填入 `vpn_region`、`vpn_peer_gateway_name`、`vpn_peer_asn`、`vpn_peer_external_ips`、`vpn_tunnels`，範例見 [examples/root/terraform.tfvars.example](examples/root/terraform.tfvars.example)。
3. 共用金鑰**不要**寫進 `terraform.tfvars`，改用 `TF_VAR_vpn_tunnel_shared_secrets` 環境變數帶入。

技術細節（HA VPN + Cloud Router BGP、SLA 等級、已知限制）見 [network-design/README.md](../network-design/README.md#cloud_vpn-module-在做什麼選用)。Dedicated/Partner/Cross-Cloud Interconnect 需要走實體線路申請流程，這裡沒有對應 module。

## 已知限制

- **Organization Policies 只套用精選子集**，不是完整 CIS Benchmark。要調整清單，改 `var.enabled_policy_ids`（見 [organization-policies/docs/policy_catalog.md](../organization-policies/docs/policy_catalog.md) 挑選其他政策）。
- **Logging 只開 Cloud Storage 歸檔**，沒有即時查詢（Log Analytics/BigQuery）能力，也沒有轉送到外部 SIEM。要臨時查某天的 log，得先用 `gcloud storage` 下載物件再自己篩，不像 BigQuery 能直接下 SQL。
- **沒有安全性產品、沒有備份 DR 服務**，這兩塊完全仰賴 GCP 預設行為（BigQuery 以外的 Data Access log 預設關閉、Cloud SQL 預設自動備份）。合規或資安團隊有明確要求時，再導入 [security-products/](../security-products/) 對應的 Terraform 範例。
- **`resource_hierarchy` 只支援 1 個 Host Project**（`shared_vpc` module 本身的限制，對應「選項 1：每個環境一個 Shared VPC」），需要多個 Shared VPC（例如多 Region 各自獨立）要另外規劃。
