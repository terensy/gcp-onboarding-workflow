# GCP Organization Policy Terraform Module

依 `policies_catalog.yaml` 產生 `google_org_policy_policy` 資源，對應
CIS Google Cloud Platform Foundation Benchmark v5.0.0 建議新增的政策項目。

完整政策清單（中英對照、依 GCP Default / CIS 分類）見
[docs/policy_catalog.md](docs/policy_catalog.md)。

如何依貴組織自己的風險與業務需求決定「哪些政策要開、開在哪個層級、值該填
什麼」，而不是把 CIS 建議照單全收，見
[docs/methodology.md](docs/methodology.md)。

## 目錄結構

```
.
├── policies_catalog.yaml          # 唯一資料來源：33 項政策的完整 metadata
├── modules/org_policies/          # 核心 module，讀 catalog 並用 for_each 產生資源
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── examples/root/                 # 可直接 terraform init/plan/apply 的範例
│   ├── main.tf
│   ├── variables.tf
│   ├── versions.tf
│   └── terraform.tfvars.example
├── docs/
│   ├── policy_catalog.md          # 33 項政策中英對照表
│   └── methodology.md             # 如何依公司內部需求調整政策的方法論
├── references/                    # CIS Benchmark 原始 PDF/CSV，供日後比對新版差異
└── scripts/
    └── verify_effective_policies.sh   # 唯讀稽核：對全部 33 項查詢實際生效狀態
```

## 快速開始

```bash
cd examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：填入 org_id、Customer ID、核准地區、folder 例外

terraform init
terraform plan
terraform apply
```

套用帳號需要 `roles/orgpolicy.policyAdmin`（或等效權限）。

## 三種分類，兩種 module 行為

`policies_catalog.yaml` 裡每條政策都有 `category`：

| category        | 數量 | module 行為                                  |
|------------------|-----|------------------------------------------------|
| `cis_gap`        | 12  | 預設會建立資源（`enabled: true`，除非另有註明）  |
| `extended`       | 2   | CIS 未直接點名但強化支援對應控制項；1 項預設開啟，1 項預設關閉待核對 |
| `auto_enforced`  | 19  | Google 已自動強制；其中 5 項 `type: boolean` 會實際建立資源，其餘 14 項仍是 `type: unverified`，**module 一律不建立資源**，只作文件對照 |

`auto_enforced` 底下這 19 項一開始全部標成 `unverified`（官方文件只給
display name / 描述，沒有給 Terraform 需要的 value schema）。但完全不
codify 這些「Google 說會自動強制」的項目，等於沒有任何機制能發現它們
其實沒生效（帳戶不合資格、地區還沒 rollout、功能被改名…）。所以拆成
兩種處理方式：

- **命名語意明確的 5 項**（單純 `disable X` / `block X` 布林開關）已改成
  `type: boolean`、`enabled: true`，會被實際 codify 成 Terraform 資源。
  這類猜錯的風險是「安全失敗」——schema 猜錯只會讓 `apply` 報錯，不會
  被靜默套用成錯誤設定，值得升級。
- **其餘 14 項**多為 list 型且需要組織特定的值（專案白名單、FQDN、服務
  名稱…），或是像 `cloudbuild.useBuildServiceAccount` 這種「Use X」命名、
  `enforce=true` 實際代表「允許」還是「阻擋」方向不明確。這類猜錯的風險
  是「成功套用但做錯事」——會通過 `apply`、但可能達成跟預期相反的效果，
  比 apply 報錯危險得多，不適合用猜的寫入，繼續維持 `unverified`。

要驗證這 14 項（以及全部 33 項）目前的**實際生效狀態**，不需要先猜對
schema：

```bash
./scripts/verify_effective_policies.sh ORG_ID
```

這是唯讀查詢，呼叫 `gcloud org-policies describe --effective`；型態由
API 回應自己標明（`booleanPolicy` / `listPolicy`），不需要人工先分類，
所以能對所有 constraint 一視同仁地「不管有沒有開都跑一遍」，給出跟猜
schema 完全無關的真實現況報告。建議定期執行（或排進 CI）以偵測 drift。

要把某一項 `unverified` 升級為可管理狀態（讓 Terraform 真的去寫入）：

1. 執行 `gcloud org-policies describe constraints/<id> --organization=ORG_ID --effective`
   確認實際 schema。
2. 把 `policies_catalog.yaml` 對應項目的 `type` 從 `unverified` 改成
   `boolean` 或 `list`，並補上 `default_mode` / `default_values`（list 型態需要）。
3. 視需要把 `enabled` 改成 `true`，或改用 root module 的
   `enabled_policy_ids` 白名單顯性指定。
4. `terraform plan` 確認產生的資源符合預期後再 `apply`。

`terraform plan` 的 `unmanaged_unverified_policies` output 會列出目前
仍被跳過的 constraint id，方便追蹤還有哪些待核對。

## Folder 層級覆寫

對應 CIS 1.1.3「依環境／敏感度分 folder」的做法。以
`var.folder_overrides` 傳入例外設定，例如讓 sandbox folder 允許外部 IP，
其餘 folder 仍繼承 organization 層級的 `deny_all`：

```hcl
folder_overrides = {
  sandbox_allow_external_ip = {
    folder_id = "987654321000"
    policy_id = "compute.vmExternalIpAccess"
    rule_type = "allow_all"
  }
}
```

`rule_type` 支援 `enforce` / `allow_all` / `deny_all` / `allowed_values` /
`denied_values`，變數已加上 `validation` 區塊擋掉打錯字的 `rule_type`。

## 新增一條政策

只要在 `policies_catalog.yaml` 補一個項目（`type` 選 `boolean` 或
`list`，`attach_level: organization`，`enabled: true/false`），module 不需要
改任何 `.tf` 檔案就會自動產生對應資源——這是選擇「for_each 動態產生」
而非外部產生器腳本的主要理由：新增/調整政策只需要改資料，不必改程式碼。

## 已知限制

- `iam.allowedPolicyMemberDomains` 的值必須是 Cloud Identity **Customer ID**
  （格式 `C0xxxxxxx`），不是網域字串本身。
- `compute.vmCanIpForward` 標記 `confidence: verify_before_use`：新一代
  managed constraint，正式命名可能為 `compute.managed.vmCanIpForward`，
  套用前請以主控台或 `gcloud org-policies list` 核對可用性。
- 本 module 只處理 Organization Policy Service 範圍內的控制項。CIS
  Benchmark 中無對應 org policy 的項目（Cloud Audit Logging、KMS 金鑰
  輪替、MFA、Access Transparency/Approval、VPC-SC、Cloud SQL 刪除保護與
  自動備份、BigQuery/Dataproc CMEK 等）不在此範圍，需另外用 Terraform
  管理個別資源設定。
