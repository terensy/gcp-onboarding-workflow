# GCP 安全性相關產品

對應最外層 [README.md](../README.md#5-安全性相關產品) 第 5 章。這幾個產品彼此獨立、用途也不同（加密、密鑰、WAF、部署把關……），不像 [organization-policies/](../organization-policies/) 或 [iam-bindings/](../iam-bindings/) 能用單一 catalog 驅動，所以這裡是各自獨立的範例，不是一個統一的 module。

## 目錄結構

```
.
├── docs/
│   └── vpc-service-controls.md    # VPC-SC 從盤點到 Enforce 的完整方法論
└── examples/
    ├── kms/                       # CMEK Key Ring / Key
    ├── secret-manager/            # Secret + IAM 存取權限 + 輪替通知
    ├── cloud-armor/               # WAF Security Policy（OWASP CRS + Rate Limiting）
    └── binary-authorization/      # Attestor + Policy（Dry-run 預設）
```

Security Command Center 跟 Assured Workloads 沒有對應的範例資料夾——前者的 Tier 訂閱是帳務層級的動作（Console/Marketplace），不是單純的 Terraform 資源；後者是特定法規場景才會用到的功能，多數導入案用不到，這裡不強做一個沒人會套用的範例。

## 各範例的套用方式

四個範例都是獨立的 root module，各自有 `versions.tf`，可以直接：

```bash
cd examples/kms   # 或 secret-manager / cloud-armor / binary-authorization
terraform init
terraform plan -var="project_id=YOUR_PROJECT" ...   # 依各範例 variables.tf 補齊必填變數
```

| 範例 | 對應章節 | 備註 |
|---|---|---|
| `kms/` | [5.3 Cloud KMS（CMEK）](../README.md#53-cloud-kmscmek) | 預設 `protection_level = SOFTWARE`，需要 FIPS 140-2 Level 3 才改 `HSM` |
| `secret-manager/` | [5.4 Secret Manager](../README.md#54-secret-manager) | 輪替通知預設關閉（`enable_rotation_notification = false`），實際輪替邏輯要自己接 Pub/Sub 實作 |
| `cloud-armor/` | [5.5 Cloud Armor](../README.md#55-cloud-armor) | 只建立 Security Policy 本身，要掛到 `google_compute_backend_service.security_policy` 才會實際生效 |
| `binary-authorization/` | [5.6 Binary Authorization](../README.md#56-binary-authorization) | `enforcement_mode` 預設 `DRYRUN_AUDIT_LOG_ONLY`，跟 VPC-SC 一樣建議先觀察再切換成真正擋 |

## VPC Service Controls

VPC-SC 沒有放進 `examples/`，因為 Perimeter 該圍哪些 Project、Access Level 該放哪些例外，是高度貴組織特定的決策，用猜的寫成通用範例反而會鼓勵跳過盤點直接套用。完整的導入方法論（官方 6 階段流程、常見踩坑、Dry-run 到 Enforce 的檢查清單）見：

- [docs/vpc-service-controls.md](docs/vpc-service-controls.md)

## 已知限制

- **`secret-manager` 範例不寫入密文內容**——密文版本要透過 CI/CD 或 `gcloud secrets versions add` 另外寫入，不建議把明文密碼放進 Terraform 程式碼或 `.tfvars`。
- **`cloud-armor` 範例的 OWASP CRS 規則版本／敏感度等級是起手式，不是最終答案**——上線前建議先用 Dry-run/Preview 模式觀察一段時間，確認沒有誤擋正常流量再轉正式套用，做法上跟 VPC-SC、Binary Authorization 的分階段導入原則一致。
- **`binary-authorization` 範例用 PGP 簽章驗證**，Google 也支援 Cloud KMS 簽章的 Attestor（可以直接沿用 `kms/` 範例產生的金鑰），如果組織已經在用 KMS 簽章流程，改用那個方式不需要另外管理 PGP 金鑰。
