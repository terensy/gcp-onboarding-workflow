# GCP 集中式 Logging Terraform Module

對應最外層 [README.md](../README.md#4-log-管理) 第 4 章。在指定的 Logging Project 裡建立 Log Analytics Bucket、長期保存用的 Cloud Storage Bucket，並把 Organization 層級的 Aggregated Sink 接過去，另外處理 Data Access Audit Log 的開關。

> [!NOTE]
> 這個 module 也被 [sme-quickstart/](../sme-quickstart/) 直接引用——中小企業版本只開 `enable_storage_archive_sink`（Cloud Storage 歸檔），`enable_analytics_sink`（BigQuery）跟 `pubsub_siem_topic_name`（SIEM 轉送）都關閉，成本最低。Logging Project 本身則由 `sme-quickstart/modules/resource_hierarchy` 建立，直接掛 Organization、不放進任何 Folder。

## 目錄結構

```
.
├── modules/aggregated_logging/    # 核心 module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
└── examples/root/                 # 可直接 terraform init/plan/apply 的範例
    ├── main.tf
    ├── variables.tf
    ├── versions.tf
    └── terraform.tfvars.example
```

## 快速開始

```bash
cd examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：填入 org_id、logging_project_id、audit_configs

terraform init
terraform plan
terraform apply
```

套用帳號需要 Organization 層級的 `roles/logging.configWriter`（建立 Sink）、`roles/resourcemanager.organizationAdmin` 或等效權限（設定 `auditConfigs`），以及目標 Logging Project 的 `roles/logging.admin` / `roles/storage.admin`（見 [iam-bindings/](../iam-bindings/) 的 `gcp-logging-admins@` 綁定）。

> [!IMPORTANT]
> `logging_project_id` 指定的 Project 要先存在（透過 [2.1 節](../README.md#21-建立-gcp-folder--project)的 Folder/Project 規劃建立），這個 module 不負責建立 Project 本身，只負責在裡面建 Log Bucket。管理這個 Project 的人應該跟一般 Workload Project 的管理員分開——能寫 log 的人跟能看/刪 log 的人如果是同一群人，稽核紀錄就失去意義了。

## module 在做什麼

三個目的地各自獨立開關，對應 Google 官方 Security Foundations Blueprint 的做法：

| 目的地 | 對應變數 | 用途 |
|---|---|---|
| Log Analytics Bucket（掛 BigQuery） | `enable_analytics_sink`（預設開） | 即時查詢、事故發生當下的 Ad Hoc 調查 |
| Cloud Storage Bucket | `enable_storage_archive_sink`（預設開） | 長期保存，預設保留 400 天 |
| Pub/Sub Topic | `pubsub_siem_topic_name`（留空則不建立） | 轉送到外部 SIEM |

每個 Sink 都是 Organization 層級、`include_children = true`，涵蓋底下所有 Folder/Project 產生的 log；Sink 的 `writer_identity`（Google 代管的服務帳戶）會自動被授予目的地的寫入權限，不需要另外手動設定。

Data Access Audit Log 用 `var.audit_configs`（`google_organization_iam_audit_config`）逐服務開關——**這不是 Organization Policy**，跟 [organization-policies/](../organization-policies/) 處理的資源完全不同，細節見最外層 README.md 4.1 節的說明。

## 已知限制

- **Bucket Lock 預設關閉**（`lock_storage_archive_bucket = false`）。這是不可逆操作，鎖定前務必先確認 `storage_archive_retention_days` 設對，見最外層 README.md 4.3 節。
- **`audit_configs` 沒有預設值**（空 map）——不主動開啟任何 Data Access log，沿用 Google 預設（BigQuery 除外，一律開啟、無法關閉）。開之前先確認範圍，Data Access log 的費用可能遠超預期。
- **只處理 Organization 層級的 Aggregated Sink**，Folder 層級的 Sink（例如只想集中某個部門/Folder 的 log）目前不在這個 module 範圍內，需要另外用 `google_logging_folder_sink` 處理。
