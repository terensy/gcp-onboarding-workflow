# GCP Landing Zone — CI/CD Bootstrap Terraform Module

對應最外層 [README.md](../README.md#7-infrastructure-as-code-基礎建設) 第 7 章。建立 Terraform State 用的 GCS Bucket，以及讓 CI/CD 能用 [Workload Identity Federation (WIF)](https://cloud.google.com/iam/docs/workload-identity-federation) 認證的 Service Account，不需要下載 Service Account 金鑰檔案。

這是刻意精簡過的版本，只處理「State 放哪裡」「CI/CD 怎麼登入」這兩個最小必要問題。如果需要完整的多階段 Landing Zone 部署管線（Org 設定、多環境 Folder、網路、Project 各自獨立的 CI/CD Pipeline），直接採用 Google 官方的 [`terraform-example-foundation`](https://github.com/terraform-google-modules/terraform-example-foundation) 會比在這個 repo 裡重造更完整、更有人維護。

## 目錄結構

```
.
├── modules/bootstrap/      # 核心 module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
└── examples/root/          # 可直接 terraform init/plan/apply 的範例
    ├── main.tf
    ├── variables.tf
    ├── versions.tf
    └── terraform.tfvars.example
```

## 快速開始

```bash
cd examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：填入 seed_project_id、cicd_project_id、
# state_bucket_name、github_repository

terraform init
terraform plan
terraform apply
```

> [!NOTE]
> 這是整個 repo 裡**唯一還需要用人工憑證 `apply` 的地方**——雞生蛋、蛋生雞：WIF 本身要先被建出來，CI/CD 才有辦法用 WIF 登入。Bootstrap 完成之後，[organization-policies/](../organization-policies/)、[iam-bindings/](../iam-bindings/)、[network-design/](../network-design/)、[logging/](../logging/) 這些子專案的 `apply` 都應該改走這裡建立的 WIF、透過 CI/CD 執行，不要繼續用個人憑證 apply 正式環境。

## module 在做什麼

1. **Terraform State Bucket**：開啟 Versioning（保留最近 N 個舊版本，避免版本無限累積）、`uniform_bucket_level_access`、`public_access_prevention = enforced`，`force_destroy = false` 防止誤刪整個 Bucket。
2. **Workload Identity Pool + GitHub Actions Provider**：只信任指定的 `github_repository`（透過 `attribute_condition` 限制），避免任何 GitHub repo 都能冒用這個 Pool 換發憑證。
3. **CI/CD Service Account**：綁定 WIF，並取得 State Bucket 的 `roles/storage.objectAdmin`（讀寫 State 檔案）。

> [!WARNING]
> 這個 module **刻意不**給 CI/CD Service Account 任何 Organization 層級的高權限角色（Organization Admin、Security Admin 之類）。要讓 CI/CD 真的能 apply [iam-bindings/](../iam-bindings/) 或 [organization-policies/](../organization-policies/)，需要另外評估該給哪些最小必要權限，透過 `iam-bindings/` 的 `extra_bindings` 明確加上去，不要因為「反正是自動化帳號、圖個方便」就整組塞 Organization Admin——Service Account 的憑證一樣可能因為 Pipeline 設定錯誤（例如 PR 從外部 fork 觸發）而被濫用，範圍越大、出事的代價越大，這跟 [2.4 節](../README.md#24-iam-角色指派)講的「先都給 Owner，之後再調」是一樣的錯誤，只是換了一個自動化的外殼。

## GitHub Actions 使用範例

```yaml
permissions:
  contents: read
  id-token: write   # WIF 需要這個權限才能換發 OIDC token

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: <terraform output 的 workload_identity_provider>
          service_account: <terraform output 的 cicd_service_account_email>
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init && terraform plan
```

## 已知限制

- 只提供 GitHub Actions 的 WIF Provider。GitLab CI/Terraform Cloud 需要另外設定 OIDC issuer，做法類似，可參考 [`terraform-example-foundation` 的對應文件](https://github.com/terraform-google-modules/terraform-example-foundation/blob/main/0-bootstrap/README-GitLab.md)。
- 沒有處理 `terraform-example-foundation` 的完整分階段架構（`0-bootstrap` ~ `4-projects`），這裡只對應到它的 `0-bootstrap` 階段裡「State + WIF」這一小塊。
