# GCP IAM 角色指派 Terraform Module

依 `bindings_catalog.yaml` 產生 `google_organization_iam_member` /
`google_billing_account_iam_member` 資源，把最外層 [README.md](../README.md#12-決定-user-來源--建立群組與人員)
1.2 節定義的 5 個最小必要管理群組，實際綁定到 GCP IAM 角色。

## 為什麼要獨立成一個 module

角色指派看起來是「console 點一點」就能做完的事，但正式環境至少會遇到三個
問題：

1. **誰在什麼時候把 Owner 角色給了誰，事後根本查不到**——console 操作沒有
   review 流程，也不會自動留下「為什麼」。
2. **Billing 帳戶的 IAM 是獨立於 Organization 的資源階層**，很多人直覺會在
   Organization 層級找 Billing Admin 的綁定位置，結果永遠找不到、或是綁錯
   層級導致權限沒生效（詳見下方「已知限制」）。
3. **群組規劃跟角色指派分成兩份文件/兩個人做**，很容易兩邊對不起來——這個
   module 直接讀最外層 README 1.2 節定義的群組，兩份資料只要有一份改了就會
   在 `terraform plan` 階段被看見。

## 目錄結構

```
.
├── bindings_catalog.yaml          # 唯一資料來源：8 筆 group → role 對應
├── modules/iam_bindings/          # 核心 module，讀 catalog 並用 for_each 產生資源
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
# 編輯 terraform.tfvars：填入 org_id、billing_account_id、domain

terraform init
terraform plan
terraform apply
```

套用帳號需要 `roles/resourcemanager.organizationAdmin`（org 層級）以及
`roles/billing.admin`（billing account 層級）。

> [!IMPORTANT]
> `terraform apply` 之前，至少要先確定 `bindings_catalog.yaml` 裡對應的
> Google Group（`gcp-organization-admins@` 等 5 個）已經在 Cloud Identity /
> Workspace 建立好，否則 `google_organization_iam_member` 會因為 member
> 不存在而 apply 失敗。順序永遠是：先建群組、再綁角色，不要顛倒。

## catalog 的設計方式

`bindings_catalog.yaml` 只存「通用邏輯」——group_key、role、scope——不寫死
任何組織的網域或群組 email，讓這份 catalog 可以跨組織重用。實際的
email 由 `terraform.tfvars` 的 `domain` 變數組出（見
`examples/root/main.tf` 的 `group_emails` 區塊）。

每筆 binding 有一個 `scope` 欄位，決定資源要綁在哪一層：

| scope | 對應資源 | 說明 |
|---|---|---|
| `organization` | `google_organization_iam_member` | 綁在 GCP Organization，會繼承到所有 Folder/Project |
| `billing_account` | `google_billing_account_iam_member` | 綁在 Cloud Billing 帳戶，**跟 Organization 是兩個獨立的資源階層** |

## 額外/例外的 IAM binding

catalog 只收錄「全公司都適用」的 8 筆 binding。如果某個 Folder 或 Project
需要額外的角色（例如 sandbox folder 的一次性 Compute Admin），透過
`var.extra_bindings` 傳入，不需要改 catalog：

```hcl
extra_bindings = {
  sandbox_compute_admins = {
    scope       = "folder"
    resource_id = "987654321000"
    role        = "roles/compute.admin"
    member      = "group:sandbox-compute-admins@example.com"
  }
}
```

`scope` 支援 `organization` / `folder` / `project` / `billing_account`，
變數已加上 `validation` 區塊擋掉打錯字的 `scope`。

## 已知限制

- **Basic role（Owner/Editor/Viewer）不在這個 module 的設計範圍內**——
  Google 官方文件明確建議正式環境避免使用 basic role，這裡刻意只支援
  predefined role。如果貴組織真的需要 basic role，請直接在 console 或另外
  的 Terraform 資源處理，不要塞進這份 catalog。
- **只處理群組層級的長期權限**，不含 [Privileged Access Manager
  (PAM)](https://cloud.google.com/iam/docs/pam-overview) 這種「臨時提權、
  用完自動收回」的機制。如果貴組織的資安基準要求高權限角色走 JIT
  （just-in-time）流程，PAM 需要另外設定，這個 module 只負責「誰長期擁有
  什麼角色」這一層。
- **不處理個人帳號的 binding**。這個 module 假設所有權限都是綁在 Google
  Group 上（呼應最外層 README 1.2 節「群組規劃」的做法）；如果發現
  `terraform plan` 想綁定一個人的 email，代表流程哪裡走歪了，先回頭檢查是
  不是漏了建立對應的群組。
- **billing_account_id 留空時，`scope: billing_account` 的 binding 會被
  整批跳過**（不會 apply 失敗，但也不會建立）——如果 `terraform plan` 顯示
  `billing_account_bindings` 是空的，先檢查 `terraform.tfvars` 有沒有填
  `billing_account_id`。
