# GCP AI 基礎設施導入（規劃中）

> [!NOTE]
> 這份文件記錄「要把 AI/ML workload(Vertex AI、Gemini Enterprise 為主)安全上線」這件事,拆解成哪些工作項目、各自該掛在哪個既有子專案底下、現在做到哪一步。**Org Policy AI 基準集(擴充既有 catalog)、Model Armor + Sensitive Data Protection([modules/ai_guardrails/](modules/ai_guardrails/))已有 Terraform 並通過 `terraform validate`**;其餘「必做 vs 選擇性」項目(治理政策、事故應變、網路 PSC module 等)仍是規劃中,還沒有對應的 Terraform 或文件產出,套用前務必先看下方「現況總覽」確認每一項的實際狀態。內容還沒有對應到最外層 [README.md](../README.md) 的章節編號,等模組更完整後再決定要不要併進去當第 9 章。

## 為什麼不是獨立的一整套新 module

跟 AWS/Azure 官方把這類 AI 治理框架包裝成一個獨立產品分類不同,這裡刻意採取跟 [network-design/docs/methodology.md](../network-design/docs/methodology.md)、[organization-policies/docs/methodology.md](../organization-policies/docs/methodology.md) 一致的立場:**AI workload 本質上還是 workload**,能沿用現有治理框架(Org Policy catalog、IAM 群組、Shared VPC、VPC-SC)的地方就沿用,只在「AI 特有」的部分才新增東西。這也是 Google 自己 2026 年之後的立場——不再建議把 AI 基礎設施另立成一個專屬分類。

安全面向的檢查清單則對齊 Google 自己的 [SAIF(Secure AI Framework)](https://saif.google/secure-ai-framework)——Data / Infrastructure / Model / Application / Assurance / Governance 六大領域,用來確保不會漏掉 Prompt Injection、Data Poisoning、Rogue Actions 這類傳統企業導入完全沒涵蓋的新型態風險。

因此下面每一項工作,都會先問「這個能力該長在既有哪個子專案裡」,答案是「新開」的才會落在這個目錄下。

## 必做 vs 選擇性

不管客戶起始狀態是什麼,以下三項是**onboarding workflow 第一天就要內建預設值、直接套用**的 Baseline,不是等客戶提需求才做;其餘項目依客戶規模/應用範圍/法遵需求再另外評估。

| 面向 | 必做/選擇性 | 理由 |
|---|---|---|
| **Org Policy AI 基準集** | **必做** | 沒有這層,後面所有防護都失去強制力——任何人都能繞過應用層的規則直接呼叫 API |
| **Model Armor** | **必做** | 現有 5.x 章節完全沒有語義層防護,這是 AI 特有、傳統企業導入補不了的洞 |
| **Sensitive Data Protection(PII)** | **必做** | AI 應用的輸入輸出是最容易外洩個資的新管道,且台灣/多數法規對 PII 外洩的裁罰门槛低,不能等出事再補 |
| **AI 用途風險分級與審核政策**(Responsible AI / Model Risk Governance) | **必要(政策層,非 Terraform)** | 屬於治理缺口,不是操作工具——沒有這層,Model Garden 白名單「誰審核、審核什麼標準」沒有依據,見下方「Responsible AI / Model Risk 治理政策」 |
| **AI 事故應變 Runbook** | **必要(文件層,非 Terraform)** | Prompt Injection 攻擊成功、模型洩漏 PII 這類事件,現有資安事故流程沒有對應分類,出事時沒有 Runbook 可用 |
| IAM 進階群組分工(`gcp-ai-platform-admins@` 等) | 選擇性 | 單一小團隊不需要拆這麼細,沿用既有 5 個群組也堪用 |
| AI 專屬 CMEK | 選擇性 | 法遵驅動,多數客戶用 Google 預設金鑰即可 |
| VPC-SC Perimeter 擴充 | 選擇性 | 風險高、需要長時間 dry-run,不該綁進「第一天就要」的範圍 |
| `vertex_ai_connectivity`(PSC 網路 module) | 選擇性 | 沒有嚴格網路隔離需求的客戶,Private Google Access 已經夠用 |
| Data Access Log 細顆粒 | 選擇性 | 依稽核需求,且成本影響大,要先問清楚範圍 |
| 進階資料治理(RAG data lake 專屬 DLP 掃描、資料居留) | 選擇性 | 沒有 RAG/訓練資料需求的客戶用不到 |
| GPU/TPU 容量與成本治理 | 選擇性,但**申請流程要儘早定義** | 只有訓練或大量自架推論才需要容量本身,但「誰能申請、怎麼歸屬成本」建議提早講清楚,見下方「GPU/TPU 容量與成本治理」 |
| AI Gateway / Agent Gateway | 條件式 | 見下方決策表,依團隊數量/多模型需求判斷 |

### Baseline 預設值(草案)

三項必做的具體預設值,目標是「先求有一道保守但不擋業務的底線」,客戶可以在這個基礎上放寬或收緊,而不是從零開始設計:

**① Org Policy AI 基準集**(擴充 `organization-policies/policies_catalog.yaml`)
- `constraints/vertexai.allowedModels` — 預設只放行 Google 首方 Gemini 系列模型;第三方/開源模型(Model Garden 上架的第三方模型)需要額外申請才開通,避免員工不受控使用未審核模型
- `constraints/iam.automaticIamGrantsForDefaultServiceAccounts` — 預設關閉(Deny),Vertex AI 相關 workload 一律要求用專屬 Service Account,不吃 default SA 的寬鬆權限

**② Model Armor**(已實作:[modules/ai_guardrails/](modules/ai_guardrails/))
- Prompt Injection / Jailbreak 偵測:預設開啟,信心度門檻先設 `MEDIUM_AND_ABOVE`(避免正常業務對話被誤擋,寧可先漏放低信心度案例,也不要一開始就因為 false positive 被客戶關掉整個防護)
- 惡意 URL 偵測:預設開啟
- 與 Sensitive Data Protection 整合:開啟(見下一項)
- **阻擋行為(`enforcement_type`)預設 `INSPECT_ONLY`**(dry-run,只記錄不擋)——這點跟原本草案「惡意 URL 預設開啟並擋下」不同,實作時改成呼應本專案 VPC-SC/Binary Authorization 一貫的 dry-run 慣例:先觀察一輪 Finding 都是預期內的違規,再由客戶決定改成 `INSPECT_AND_BLOCK`,不要一套用就直接擋線上流量

**③ Sensitive Data Protection(PII)**(已實作,跟 Model Armor 同一個 module)
- 預設 infoType 清單:`EMAIL_ADDRESS`、`PHONE_NUMBER`、`CREDIT_CARD_NUMBER`、`PERSON_NAME`、`STREET_ADDRESS` 這五個 Google 官方 built-in infoType
- **身分證字號另外處理**:Google 官方 built-in infoType 清單裡沒有可確認的「台灣身分證字號」項目,實作時沒有用猜的 infoType 名稱,改用 `custom_info_types` + regex 做格式比對(1 碼英文字母 + 9 碼數字,只驗證格式、不是官方檢查碼演算法),透過 `enable_custom_id_pattern` 開關控制,套用前務必跟客戶法遵確認是否符合實際需求
- 預設動作:偵測到 → **去識別化/遮蔽(character mask,整個 finding 用 `*` 蓋掉)**,不是整段擋掉——擋掉會直接影響業務對話流程,先用遮蔽降低外洩風險
- 適用範圍:第一版只涵蓋 Model Armor 即時檢查這一段(prompt/response);掃描 RAG data lake 屬於「進階資料治理」,是選擇性項目,不在第一天的 Baseline 內

> [!NOTE]
> 這三項預設值都是**保守起點**,不是最終答案——實際門檻、允許的模型清單、PII 類型都要跟客戶的法遵/資安單位確認過一次,但「有一版預設值可以先套用、之後再調」比「等客戶自己想清楚所有細節才開始」更務實,這也是為什麼要把它們定位成 onboarding workflow 第一天就內建,而不是等客戶主動提出需求。

## 不分客戶情境,用同一份 Baseline + Preflight skip-if-exists

原本想針對「全新客戶／已走過本專案／用了一段時間但沒走過本專案」規劃三條不同路徑,但三條路徑會讓 onboarding workflow 的維護成本跟決策複雜度都上升,而且客戶自己也很難準確判斷自己屬於哪一種。改成更簡單的做法:**不分情境,一律套用同一份 idempotent 的 AI Baseline**,差別只在套用前先跑 Preflight 檢查、已存在的設定自動跳過或提示衝突,而不是重新規劃三套流程。

### Preflight 檢查(規劃中)

延伸 [organization-policies/scripts/verify_effective_policies.sh](../organization-policies/scripts/verify_effective_policies.sh) 「只讀、不改動,先確認實際生效狀態」的既有慣例,套用 Baseline 前先跑一次只讀盤點,而不是預先假設客戶的起始狀態:

- 現有 Org Policy 是否已經有跟 AI 相關的 constraint 被設過(可能是別的顧問或內部團隊自己加的)→ 有就比對差異,不盲目覆蓋
- 現有 IAM 是否已經有人被授予 `roles/aiplatform.*` 系列角色
- Vertex AI API 是否已啟用、是否已有 workload 在跑——如果有,代表任何會擋流量的設定(例如 VPC-SC Perimeter enforce)都必須先跑 dry-run,不能直接套用
- 套用 Baseline 後跑一次 `terraform plan`,確認 diff 只包含預期新增的資源

這支腳本的產出只回答一個問題:「現在套 Baseline 安不安全」,不用先幫客戶歸類是哪一種情境。

## 現況總覽

| 面向 | 必做/選擇性 | 對應既有子專案 | 現況 | 說明 |
|---|---|---|---|---|
| Model Garden 白名單 | **必做** | [organization-policies/](../organization-policies/) | **Catalog 已新增,`enabled: false`** | `constraints/vertexai.allowedModels` 已加入 `policies_catalog.yaml`(category: extended),因 schema 未對照客戶實際 org 驗證過,標記 `confidence: verify_before_use`,套用前需先跑 `gcloud org-policies describe constraints/vertexai.allowedModels --organization=ORG_ID --effective` 核對,確認無誤後把 `enabled` 改 `true` |
| Service Account 治理(關閉 default SA 自動授權) | **必做** | [organization-policies/](../organization-policies/) | **Catalog 已新增,`enabled: true`** | `constraints/iam.automaticIamGrantsForDefaultServiceAccounts` 已加入 `policies_catalog.yaml`,schema 已於官方文件確認為單純 boolean,可直接跑 `terraform plan` 套用 |
| **語義層安全防護(Model Armor)** | **必做** | [modules/ai_guardrails/](modules/ai_guardrails/) | **Terraform 已建立,`terraform validate` 通過** | Prompt Injection/Jailbreak 偵測、惡意 URL 偵測;`enforcement_type` 預設 `INSPECT_ONLY`(dry-run),預設值見上方「Baseline 預設值」 |
| **Sensitive Data Protection(PII)** | **必做** | [modules/ai_guardrails/](modules/ai_guardrails/) | **Terraform 已建立,`terraform validate` 通過** | 結合 Model Armor 做即時 PII 偵測/遮蔽,同一個 module 一起產生;身分證字號用 custom regex 而非猜測的 infoType,預設值見上方「Baseline 預設值」 |
| **AI 用途風險分級與審核政策** | **必要(政策層)** | 待新增 | 未開始 | 見下方「Responsible AI / Model Risk 治理政策」 |
| **AI 事故應變 Runbook** | **必要(文件層)** | 待新增 | 未開始 | 見下方「AI 特有的事故應變」 |
| IAM 進階群組分工 | 選擇性 | [iam-bindings/](../iam-bindings/) | 待評估 | `gcp-ai-platform-admins@` / `gcp-ml-engineers@` 兩個新群組,單一小團隊可沿用既有 5 個群組 |
| AI 專屬 CMEK 要求 | 選擇性 | [organization-policies/](../organization-policies/) | 待評估 | 評估是否把 `aiplatform.googleapis.com` 納入既有 `gcp.restrictNonCmekServices`,法遵驅動 |
| Private Service Connect 連線 | 選擇性 | [network-design/](../network-design/) | **待新增 module** | Vertex AI Online Prediction / Pipelines / Agent Engine 的 PSC endpoint,見下方「網路」小節 |
| VPC-SC Perimeter 擴充 | 選擇性 | [security-products/docs/vpc-service-controls.md](../security-products/docs/vpc-service-controls.md) | 規劃中 | 把 `aiplatform.googleapis.com` 納入既有 Perimeter,走既有 dry-run 流程 |
| Data Access Log 細顆粒 | 選擇性 | [logging/](../logging/) | 待評估 | `aiplatform.googleapis.com` 的 Data Access log 是否要開、開到什麼粒度(是否含 prompt/response 內容)尚未決定 |
| 進階資料治理(RAG 用的 GCS/BigQuery、DLP 掃描) | 選擇性 | 待新增 | 未開始 | 目前沒有對應子專案,需求還在釐清 |
| GPU/TPU 容量與成本治理 | 選擇性(申請流程建議提早定義) | 待新增 | 未開始 | 見下方「GPU/TPU 容量與成本治理」 |
| **AI Gateway(Apigee / API Gateway model routing)** | 條件式 | 待新增 | **見決策表** | 不是必裝模組,依團隊數量/多模型需求判斷是否導入 |
| Agent 治理(Agent Gateway、A2A 資料保護) | 條件式 | 待新增 | 未開始 | 僅在客戶使用 Gemini Enterprise Agent Platform 等 agentic workload 時才需要評估,不預設涵蓋在本專案範圍 |

## GCP 設定 vs 純文件/流程

排 Sprint 前要先分清楚:哪些項目要寫 Terraform、對應具體的 GCP 資源,哪些純粹是文件/審核流程,不會產生任何 `terraform plan` diff。避免把治理缺口誤判成「反正不用動 GCP,不急」。

**實際需要在 GCP 上設定的項目**

| 項目 | 對應 GCP 資源/API |
|---|---|
| Org Policy AI 基準集 | ✅ `google_org_policy_policy`——`constraints/vertexai.allowedModels`、`constraints/iam.automaticIamGrantsForDefaultServiceAccounts`(Organization Policy Service),已加入 `organization-policies/policies_catalog.yaml` |
| Model Armor | ✅ `google_model_armor_template`(Prompt Injection/Jailbreak、惡意 URL 偵測規則),已實作於 [modules/ai_guardrails/](modules/ai_guardrails/) |
| Sensitive Data Protection(PII) | ✅ `google_data_loss_prevention_inspect_template` + `google_data_loss_prevention_deidentify_template`,已實作於 [modules/ai_guardrails/](modules/ai_guardrails/),從 Model Armor Template 的 `sdp_settings` 引用 |
| IAM 進階群組分工 | `google_organization_iam_member` / `google_project_iam_member`(群組本身在 Cloud Identity 建,角色綁定才是 GCP IAM) |
| AI 專屬 CMEK | Cloud KMS Key Ring/Key + Org Policy `gcp.restrictNonCmekServices`、`gcp.restrictCmekCryptoKeyProjects` |
| VPC-SC Perimeter 擴充 | `google_access_context_manager_service_perimeter`,把 `aiplatform.googleapis.com` 加進受保護服務清單 |
| `vertex_ai_connectivity`(PSC) | `google_compute_network_attachment`(Host Project)+ Vertex AI Endpoint 的 `private_service_connect_config` |
| Data Access Log 細顆粒 | `google_project_iam_audit_config` 或 Organization 層級的 IAM Audit Config,開啟 `aiplatform.googleapis.com` 的 Data Access log |
| 進階資料治理(RAG DLP 掃描、資料居留) | DLP Job Trigger 掃描 GCS/BigQuery + Org Policy `gcp.resourceLocations` |
| GPU/TPU Quota/Reservation | Compute Engine Reservation、Quota 調整申請(Console/API) |
| GPU/TPU 成本歸屬 | Labels 掛在資源上,銜接既有 Billing Export to BigQuery |
| GPU/TPU 異常降級 | Budget Alert + Pub/Sub + Cloud Function/Run 自動化 |
| AI Gateway / Agent Gateway(條件式) | Apigee Organization/Proxy 設定、API Gateway model routing——重工程,通常是獨立於本 repo 的專案 |

**純文件/流程,不動 GCP**

| 項目 | 說明 |
|---|---|
| AI 用途風險分級與審核政策 | 純組織內部治理流程與文件,沒有對應的 GCP 資源 |
| AI 事故應變 Runbook | 本體是文件;唯一會碰到 GCP 的地方是「Model Armor Finding 要不要併入 Security Command Center」這條整合路徑(如果做,才變成上表的 SCC 自訂來源設定) |
| GPU/TPU「誰能申請」審核流程 | 流程本身是文件,實際的 Quota/Reservation 才是 GCP 設定(見上表) |
| Preflight 現況盤點腳本 | 是唯讀查詢腳本(`gcloud ... --effective`、`terraform plan`),不改動任何 GCP 設定,只是讀取現況 |

> [!IMPORTANT]
> 三項必做 Baseline 裡,真正需要新建 GCP 資源的是 Org Policy、Model Armor、Sensitive Data Protection 這三個;另外兩個「必要」項目(風險分級政策、事故應變 Runbook)完全不碰 GCP。**不能因為「不用在 GCP 上設定」就把這兩項排到 Sprint 後面**——上一輪分析已經確認這是治理層真正的缺口,優先度跟另外三項一樣高,只是產出形式是文件而不是 Terraform diff。

## 目錄結構

```
ai-onboarding/
├── README.md                      # 本檔案
├── .gitignore                     # 比照其他子專案：忽略 .terraform/、tfstate、tfvars
├── docs/
│   └── methodology.md             # 待新增：AI 治理決策框架
├── modules/
│   ├── ai_guardrails/              # ✅ 已實作：Model Armor + DLP Inspect/De-identify Template
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── vertex_ai_connectivity/    # 待新增：Vertex AI 的 PSC Network Attachment / Endpoint，掛進既有 Shared VPC
└── examples/root/                 # ✅ 已實作：呼叫 ai_guardrails 的最小範例
    ├── main.tf
    ├── variables.tf
    ├── versions.tf
    └── terraform.tfvars.example
```

> [!NOTE]
> `modules/ai_guardrails/` 已通過 `terraform validate`(provider `hashicorp/google` v8.3.0),對應「必做 vs 選擇性」的 Model Armor + Sensitive Data Protection 兩項。`docs/methodology.md` 跟 `modules/vertex_ai_connectivity/` 仍是規劃中,還沒有實際檔案。

## 網路:為什麼需要一個新 module,而不是塞進 `shared_vpc`

[network-design/modules/shared_vpc](../network-design/modules/shared_vpc) 目前處理的是「一般 workload」的子網路、Private Google Access、Cloud NAT。Vertex AI 的 Online Prediction / Pipelines / Agent Engine 要用 Private Service Connect **Interface**(不是單純的 PSC endpoint),需要:

1. Host Project 建 `google_compute_network_attachment`
2. Service Project 端的 Vertex AI 資源(Endpoint / Index Endpoint / Pipeline)指到這個 Attachment

這跟 `shared_vpc` module 現有的職責(建 VPC、掛 Service Project、開 NAT)性質不同,所以規劃成獨立的 `vertex_ai_connectivity` module,跟 `cloud_vpn` 一樣是**選用**、由 `enable_*` 開關控制,不影響沒有 AI workload 的既有使用者。

> [!WARNING]
> Terraform Google Provider 對 Vertex AI PSC 的支援還在陸續補齊中(`google_vertex_ai_endpoint`、`google_vertex_ai_index_endpoint` 的 `private_service_connect_config` 部分屬性仍有 open issue),實作前要先確認當下 provider 版本支援到什麼程度,不要假設文件寫的欄位都已經可用。

## AI 安全防護分層

對齊 SAIF 六大領域(Data / Infrastructure / Model / Application / Assurance / **Governance**),實際落到 GCP 產品大致分六層,由外而內:

1. **語義層**——[Model Armor](https://cloud.google.com/security/products/model-armor):即時檢查 prompt/response 內容本身,防 Prompt Injection/Jailbreak,結合 Sensitive Data Protection 偵測並遮蔽 PII/信用卡號/憑證,擋惡意 URL。這是既有 5.x 章節(SCC/VPC-SC/KMS/Cloud Armor)完全沒有對應物的全新一層,防護對象是「內容」而不是「連線」或「權限」。
2. **模型存取控制層**——Model Garden 白名單(`vertexai.allowedModels`)、Service Account 治理。
3. **網路層**——VPC-SC 涵蓋 `aiplatform.googleapis.com`、PSC/restricted VIP 避免流量出網。
4. **資料層**——Sensitive Data Protection 掃描訓練資料/RAG 用的 GCS/BigQuery、CMEK 涵蓋靜態加密。
5. **稽核/可觀測層**——Data Access log 粒度,或改在 AI Gateway 層統一收集 token 用量、呼叫方、model 選擇。
6. **治理層(Governance)**——AI 用途風險分級、審核政策、事故應變 Runbook,對應 SAIF 的 Governance domain,是純政策文件而非 Terraform,見下方兩節。

> [!NOTE]
> 落地順序建議 Model Armor(語義層)優先於 AI Gateway——Model Armor 可以先掛在 Vertex AI 或單一應用上直接生效,不需要先蓋好整個閘道平台才能有防護,符合現有專案「先求有護欄,不是先求有平台」的一貫立場。治理層(第 6 層)雖然排在最後說明,但實際上應該跟第 1-3 層同一批次動工,因為它是「Model Garden 白名單開放到什麼程度」這類判斷的依據,不是事後補的東西。

如果客戶用的是 Gemini Enterprise Agent Platform 這類 agentic workload,風險面會再往上疊一層——工具調用權限(Agent 能不能呼叫外部 API/資料庫)、A2A(Agent-to-Agent)協定的資料保護,需要額外評估 **Agent Gateway**,不要預設本文件自動涵蓋 Agent 治理。

## Responsible AI / Model Risk 治理政策(第 6 層:Governance)

這一節補的是「政策」不是「工具」——重新研究業界 AI 基礎設施治理案例後發現,這是本文件原本最大的缺口:有語義層防護(Model Armor)、有模型存取控制(白名單),但沒有「誰來決定白名單放行標準」「哪些用途不能用 AI」這一層治理依據。

- **AI 用途風險分級**:區分「低風險」(內部效率工具、草稿生成、內部知識庫問答)vs「高風險」(涉及信用審核、招聘篩選、醫療/法律建議這類會直接影響個人權益的決策)——高風險用途要走額外審核,不能直接套用預設 Baseline 就上線
- **審核流程**:誰批准新的 AI use case 上線?是否沿用既有 `gcp-security-admins@`,或需要新增一個跨部門的 AI 治理小組(成員通常要包含法遵/業務,不能只有 IT)
- **Model Garden 白名單審核 cadence**:新模型申請的 SLA(例如 5 個工作天內給結果)、既有白名單的複審週期(例如每季一次),把上一輪開放問題的「由誰審核、多久 review」落成具體條文
- **人類監督要求**:高風險用途是否強制要求人類做最終決定,AI 只能輔助、不能自動執行(例如自動核准信用額度不行,AI 生成建議、人類簽核可以)
- **透明度揭露義務**:使用者是否被告知自己在跟 AI 互動——如果客戶所在地有 AI 專法(例如歐盟 AI Act、台灣研議中的 AI 基本法)要另外對照,本文件不預設涵蓋特定法規的合規細節

> [!IMPORTANT]
> 這一節目前只有框架,沒有具體條文——實際的風險分級標準、審核 SLA、治理小組成員都要跟客戶的法遵/業務單位確認過,不是 IT 團隊可以單方面定義的。

## AI 特有的事故應變

現有主 [README.md](../README.md) 第 5 章的資安事故因應完全沒有涵蓋「語義層事件」這個分類,SCC 的 Finding 分類也不會自動涵蓋。這裡先列出雛形,實際 Runbook 要跟既有資安事故流程整合,不是另起爐灶:

- **事故分類**:Prompt Injection 攻擊成功繞過 Model Armor、模型輸出洩漏 PII、模型輸出造成商業損害的錯誤資訊(幻覺導致的誤導性內容)、越獄(Jailbreak)成功案例
- **分級與通報路徑**:Model Armor 的偵測結果是否要送進既有 Security Command Center 當一種 Finding 來源,還是另開一條通報路徑,兩者對應的處理速度跟究責對象不同
- **最小 Runbook 雛形**:發現模型洩漏 PII → 立即降級該端點到人工審核,或暫停該模型的 Model Garden 白名單 → 通知法遵 → 限期完成根因分析。參考主 README 5.2 節 VPC-SC 事故「先擋、再查」的處理邏輯,同一套思路搬過來用

> [!NOTE]
> 這節目前是雛形,不是可執行的 Runbook——真正落地前要先確認「Model Armor Finding 進 SCC」這條整合路徑在 Terraform 層面怎麼接,目前沒有驗證過。

## GPU/TPU 容量與成本治理

容量規劃本身(要不要用 Reservation)是選擇性的,但「誰能申請、成本怎麼歸屬」建議提早定義,避免帳單爆表才回頭補治理:

- **Quota 申請流程**:誰能申請 GPU/TPU Quota、誰審核——比照主 README 2.3 節 Billing 角色分工的邏輯,不能沒有審核就讓任何人申請高成本容量
- **成本歸屬**:比照現有 Labels(`environment`/`cost-center`/`team`)慣例,AI workload 加一個 `component=vertex-ai` 或類似維度,才能回答「這個月 AI 花了多少錢、是哪個團隊燒的」,銜接既有 2.3 節的 Billing Export to BigQuery
- **異常用量自動降級**:呼應主 README 2.3 節「Alerts only 預算不會自動踩剎車」的教訓——如果 Prompt Injection 攻擊導致大量重複呼叫使費用暴衝,要不要接 Pub/Sub 自動降級/停用該端點,而不是等帳單出來才發現

## 明確排除聲明

以下項目**刻意不在本專案範圍**,屬於使用平台的應用/資料團隊該建置的範疇,不是「讓大家能安全使用平台」的地基層:

- MLOps CI/CD pipeline、Model Registry 版本控管
- Vertex AI Model Monitoring(訓練-推論偏移、預測漂移偵測)
- Vector DB/RAG pipeline 的技術設計
- Agent 應用邏輯本身(工具串接、prompt engineering)

這跟主 [README.md](../README.md) 完全沒有涵蓋 GKE 應用部署 CI/CD 是同一個原則——企業導入管地基,不管地基上蓋的房子。需要這些能力,參考 Google 官方 [genai-mlops-blueprint](https://docs.cloud.google.com/architecture/blueprints/genai-mlops-blueprint)。

## AI Gateway:條件式導入,不是必裝模組

AI Gateway(Apigee AI Gateway / Google Cloud API Gateway 的 model routing)解決的是 Token/Rate Limiting、多模型路由與 failover、Semantic Caching、集中套用 Model Armor policy 這些**應用層/平台層**的問題,不是傳統企業導入管的「網路可達、身份治理、護欄、稽核」範疇——這跟現有 README 完全沒有涵蓋「一般 API Gateway/Apigee for 傳統 workload」是一致的邏輯。

但如果沒有一個集中的 ingress 點,Model Armor 這種語義層防護會變成每個團隊自己接、力道各自為政。因此用決策表取代「要/不要」的二選一:

| 判斷條件 | 建議 |
|---|---|
| 單一應用、單一團隊、只用 Vertex AI 一家模型 | **不需要** Apigee AI Gateway,Model Armor 直接掛在 Vertex AI safety filter 或應用自己呼叫 API 即可,上閘道是過度工程 |
| 多團隊/多應用,需要統一計費、統一稽核 | **需要**,Apigee 當強制 ingress,統一套 rate limit + Model Armor policy + token 計量 |
| 有串接第三方模型(非 Google),或需要 model failover | **需要**,這是 Vertex AI 原生機制管不到的範圍,必須靠 Gateway 層的 model routing |
| 有 Agentic workload(Gemini Enterprise Agent Platform) | 另外評估 **Agent Gateway**,跟一般 LLM API Gateway 是不同的產品線,不要混為一談 |

落地建議比照 `cloud_vpn` module 的模式——**選用、有明確的 `enable_*` 開關**,不建議放進 Terraform module 直接生成 Apigee 資源(Apigee 的組織級設定牽涉授權模式/定價層級,比 VPN 更重)。客戶明確落在「需要」那幾格,才展開實際的 Apigee 導入,且很可能是獨立於本 repo 的專案。

## 建議落地順序

1. **Preflight 現況盤點**——不分客戶情境,套用 Baseline 前一律先跑,確認哪些設定已存在、哪些是全新套用
2. **必做 Baseline + 治理政策(同一批次做完)**:
   - **Org Policy AI 基準集**(`vertexai.allowedModels`、關閉 default SA 自動授權)——✅ 已加入 `organization-policies/policies_catalog.yaml`(見下表),`iam.automaticIamGrantsForDefaultServiceAccounts` 可直接套用,`vertexai.allowedModels` 待對照實際 org 驗證 schema 後啟用
   - **Model Armor + Sensitive Data Protection(PII)**——✅ 已建立 [modules/ai_guardrails/](modules/ai_guardrails/),`terraform validate` 通過(provider `hashicorp/google` v8.3.0)。`enforcement_type` 預設 `INSPECT_ONLY`(dry-run),套用後要先觀察一輪 Finding,確認都是預期內違規再改成 `INSPECT_AND_BLOCK`;實際 `terraform apply` 前還需要：① 填 `examples/root/terraform.tfvars` 的 `project_id`、② 確認 `location` 有 Model Armor 支援、③ 跟法遵確認 `custom_id_pattern` 的身分證字號格式是否符合需求
   - **Responsible AI / Model Risk 治理政策**——雖然是文件而非 Terraform,但要跟上面同批做完,因為白名單放行標準要靠這份政策當依據,不是事後補的東西
   - **AI 事故應變 Runbook 雛形**——至少先定義分類跟通報路徑,細節可以後續補
3. **GPU/TPU Quota 申請流程與成本歸屬**——即使還沒有實際訓練/推論需求,審核流程跟 Label 維度建議跟第 2 步一起定義,避免帳單爆表才回頭補治理
4. **VPC-SC Perimeter 擴充**(選擇性)——沿用既有 dry-run 方法論,依客戶法遵需求評估
5. **`vertex_ai_connectivity` 網路 module**(選擇性)——工程量最大,且是「事後最難改」的一塊,只有需要嚴格網路隔離的客戶才做,要留最多時間做決策與測試
6. IAM 群組、Logging 粒度、進階資料治理(選擇性)——依需求陸續評估,彼此依賴度低,不急著同時做
7. **AI Gateway / Agent Gateway**(條件式)——只在決策表判定「需要」時才展開,不是預設項目

## 開放問題(動工前要先有答案)

必做項目本身的細節(即使先套用保守預設值,仍要儘快跟客戶確認,避免 Baseline 長期停在「先求有」的狀態):

- Model Garden 白名單由誰審核、多久 review 一次?保守預設(僅 Gemini 首方模型)多久要重新盤點一次?
- PII 的 infoType 清單跟遮蔽/擋下的動作,是否符合客戶所在地實際法規要求(而不是只套用通用預設)?
- AI 用途的風險分級標準怎麼訂?哪些用途算「高風險」需要額外審核,由誰拍板?
- Model Armor 的 Finding 要不要併入既有 SCC 通報路徑?這條整合目前沒有驗證過

選擇性項目要不要做,取決於以下問題的答案:

- Data Access log 要記錄「誰呼叫了 API」還是「呼叫內容本身」?後者涉及法遵/隱私,不是單純開關問題
- 是否有資料居留(Data Residency)要求,限制訓練資料/向量庫只能落在特定 Region?
- 第三方模型(非 Google)的 API 呼叫,走不走 VPC-SC 邊界內?出向流量怎麼管?
- 客戶有幾個團隊/應用要用 AI?會不會串第三方模型?——這兩題直接決定 AI Gateway 決策表落在哪一格
- 客戶是否需要嚴格網路隔離(PSC),還是 Private Google Access 已經夠用?

這些問題目前都還沒有答案,動工前建議先跟業務/法遵單位確認,而不是先把 Terraform 寫出來再回頭套。
