# GCP AI 基礎設施導入

對應最外層 [README.md](../README.md) 的企業級導入流程，補上 AI/ML workload（Vertex AI、Gemini Enterprise 為主）需要的額外治理與護欄。**AI workload 本質上還是 workload**：身分、網路、稽核、VPC-SC 這些基礎治理，沿用 [organization-policies/](../organization-policies/)、[iam-bindings/](../iam-bindings/)、[network-design/](../network-design/)、[security-products/](../security-products/) 既有子專案即可，這裡只處理「AI 特有」、其他章節管不到的部分：Model Garden 白名單、語義層防護（Model Armor）、PII 偵測與遮蔽（Sensitive Data Protection）。

## 目錄結構

```
.
├── modules/
│   └── ai_guardrails/          # Model Armor Template + DLP Inspect/De-identify Template
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── examples/root/              # 可直接 terraform init/plan/apply 的最小範例
    ├── main.tf
    ├── variables.tf
    ├── versions.tf
    └── terraform.tfvars.example
```

## 快速開始

```bash
cd examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：project_id、location
# 第一次套用建議保持 enforcement_type = INSPECT_ONLY（dry-run），
# 觀察一輪 Finding 都是預期內的違規後，再改成 INSPECT_AND_BLOCK

terraform init
terraform plan
terraform apply
```

套用帳號需要 Model Armor 與 Sensitive Data Protection 的管理權限（`roles/modelarmor.admin`、`roles/dlp.admin`，或等效權限）。

## 涵蓋範圍

| 面向 | 對應資源 | 說明 |
|---|---|---|
| Model Garden 白名單 | [organization-policies/](../organization-policies/) 的 `constraints/vertexai.allowedModels` | 限制可用的模型與動作（predict/tune/deploy），預設保守值僅放行 Google 首方 Gemini 系列 |
| Service Account 治理 | 同上，`constraints/iam.automaticIamGrantsForDefaultServiceAccounts` | 關閉 default service account 自動取得 `roles/editor` 的行為，Vertex AI 相關 workload 一律用專屬 Service Account |
| 語義層防護（Model Armor） | `modules/ai_guardrails/` | Prompt Injection/Jailbreak 偵測、惡意 URL 偵測 |
| PII 偵測與遮蔽（Sensitive Data Protection） | `modules/ai_guardrails/` | 偵測到常見 PII 時去識別化（遮蔽），不是整段擋掉 |

Org Policy 這兩條直接寫在 [organization-policies/policies_catalog.yaml](../organization-policies/policies_catalog.yaml) 裡（隸屬 `extended` 分類），套用方式跟其他政策一樣，見 [organization-policies/README.md](../organization-policies/README.md)。

## `ai_guardrails` module 在做什麼

1. **`google_data_loss_prevention_inspect_template`**：偵測 Email、電話、信用卡卡號、姓名、地址等常見 PII（`var.pii_info_types` 可調整）；身分證字號另外用 `custom_info_types` + regex 做格式比對（`var.enable_custom_id_pattern`），因為 Google 官方 built-in infoType 清單裡沒有可確認對應的項目。
2. **`google_data_loss_prevention_deidentify_template`**：對應上面偵測到的每個 infoType，用 character mask（整個 finding 用 `*` 蓋掉）做去識別化，不是整段擋掉請求。
3. **`google_model_armor_template`**：Prompt Injection/Jailbreak 偵測（`var.prompt_injection_confidence` 預設 `MEDIUM_AND_ABOVE`）、惡意 URL 偵測，並透過 `sdp_settings.advanced_config` 掛上前兩個 DLP Template。

> [!IMPORTANT]
> `var.enforcement_type` 預設 `INSPECT_ONLY`（只記錄 Finding、不擋流量）——呼應本專案 [VPC-SC](../security-products/docs/vpc-service-controls.md)、Binary Authorization 一貫的「先 dry-run 觀察，確認不會誤擋正常業務流程，再 enforce」慣例。觀察期沒有固定天數，取決於業務的使用模式複雜度；確認 Finding 都是預期內的違規之後，再把 `enforcement_type` 改成 `INSPECT_AND_BLOCK`。

## 需要自行決定的治理事項

以下項目沒有對應的 Terraform 資源，屬於組織治理政策，套用上面的 Terraform 前建議先有答案：

- **AI 用途風險分級**：哪些用途屬於高風險（例如涉及信用審核、招聘篩選、醫療/法律建議這類會直接影響個人權益的決策），需要額外的人工審核，不能只套用預設 Baseline 就上線。
- **Model Garden 白名單審核流程**：誰能核准新模型上線、SLA 多長、既有白名單多久複審一次。
- **AI 事故應變**：Prompt Injection 攻擊成功繞過 Model Armor、模型輸出洩漏 PII 等事件，要走哪一條通報路徑（例如併入既有 Security Command Center 的 Finding 通報，或另開專屬流程）、由誰負責、分幾級。
- **GPU/TPU 容量與成本**：Quota/Reservation 由誰申請、誰審核；成本歸屬建議延用主 README [8.1 節](../README.md#81-資源-tagging--labeling-策略)的 Labels 慣例，加一個 `component=vertex-ai` 之類的維度。

## 要不要導入 AI Gateway

AI Gateway（Apigee AI Gateway／Google Cloud API Gateway 的 model routing）處理的是 Token/Rate Limiting、多模型路由、集中套用 Model Armor policy 這些應用層/平台層的問題，**不是這個子專案的必裝項目**：

| 判斷條件 | 建議 |
|---|---|
| 單一應用、單一團隊、只用 Vertex AI 一家模型 | 不需要，Model Armor 直接掛在 Vertex AI 或應用上即可 |
| 多團隊/多應用，需要統一計費、統一稽核 | 需要，Apigee 當強制 ingress，統一套 rate limit + Model Armor policy + token 計量 |
| 有串接第三方模型（非 Google），或需要 model failover | 需要，這是 Vertex AI 原生機制管不到的範圍 |
| 有 Agentic workload（Gemini Enterprise Agent Platform） | 另外評估 Agent Gateway，跟一般 LLM API Gateway 是不同產品線 |

Apigee 的組織級設定牽涉授權模式與定價層級，比一般 Terraform module 重得多，不建議放進這個子專案直接生成資源；落在「需要」那幾格時，另外開獨立專案評估導入。

## 不在這個子專案範圍內

以下項目屬於使用平台的應用/資料團隊該建置的範疇，不是治理地基層，刻意不涵蓋：

- MLOps CI/CD pipeline、Model Registry 版本控管
- Vertex AI Model Monitoring（訓練-推論偏移、預測漂移偵測）
- Vector DB/RAG pipeline 的技術設計
- Agent 應用邏輯本身（工具串接、prompt engineering）
- Vertex AI 的 Private Service Connect 網路連線（規劃中，尚未實作；沒有嚴格網路隔離需求的話，[network-design/](../network-design/) 既有的 Private Google Access 已經夠用）
- VPC-SC Perimeter 涵蓋 `aiplatform.googleapis.com`（沿用 [security-products/docs/vpc-service-controls.md](../security-products/docs/vpc-service-controls.md) 既有的 dry-run 方法論自行擴充，未內建在本子專案）

需要 MLOps/Model Registry 這類能力，參考 Google 官方 [genai-mlops-blueprint](https://docs.cloud.google.com/architecture/blueprints/genai-mlops-blueprint)。

## 已知限制

- `constraints/vertexai.allowedModels` 的 schema 取自 Google 官方文件，尚未對照實際 Organization 用 `gcloud org-policies describe constraints/vertexai.allowedModels --organization=ORG_ID --effective` 驗證過，因此 `policies_catalog.yaml` 裡標記 `confidence: verify_before_use`、`enabled: false`——套用前請先跑驗證指令核對，確認無誤後再改成 `enabled: true`。
- 身分證字號偵測（`var.custom_id_pattern`）只做正規表示式的格式比對，不是官方檢查碼演算法，也不保證涵蓋貴組織所在地的實際法規要求，套用前請跟法遵確認。
- `google_model_armor_template` 是 2025 年後才加入 `hashicorp/google` provider 的資源，`modules/ai_guardrails/versions.tf` 目前設定 `>= 6.30.0`；`terraform init` 若回報版本不符，請對照 [Terraform Registry](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/model_armor_template) 調整下限。
- Model Armor 目前僅部分 Region 支援，`var.location` 套用前請以 [Model Armor 官方文件](https://cloud.google.com/security/products/model-armor) 核對可用性。
