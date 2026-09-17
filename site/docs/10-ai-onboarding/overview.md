---
title: AI 基礎設施導入
description: 在既有企業級導入基礎上，加裝 AI/ML workload（Vertex AI、Gemini Enterprise）需要的治理與護欄——Model Garden 白名單、Model Armor 語義層防護、Sensitive Data Protection。
keywords: [AI onboarding, Vertex AI, Gemini Enterprise, Model Armor, Sensitive Data Protection, GCP AI governance]
sidebar_position: 1
---

# 10. AI 基礎設施導入

如果貴公司的 GCP 導入範圍包含 AI/ML workload（Vertex AI、Gemini Enterprise 為主），前面章節的治理框架（Organization Policies、IAM、網路、Logging、安全性產品）大部分可以直接沿用——AI workload 本質上還是 workload，不需要另立一套獨立的治理分類。這一章記錄的是「AI 特有」、傳統章節補不到的部分，對應 [`ai-onboarding/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding) 這個 Terraform 子專案。

## 涵蓋範圍

| 面向 | 對應資源 | 說明 |
| --- | --- | --- |
| Model Garden 白名單 | [Organization Policies](/organization-setup/organization-policies) 的 `constraints/vertexai.allowedModels` | 限制可用的模型與動作（predict/tune/deploy），預設保守值僅放行 Google 首方 Gemini 系列 |
| Service Account 治理 | 同上，`constraints/iam.automaticIamGrantsForDefaultServiceAccounts` | 關閉 default service account 自動取得 `roles/editor` 的行為 |
| 語義層防護（Model Armor） | `ai-onboarding/modules/ai_guardrails/` | Prompt Injection/Jailbreak 偵測、惡意 URL 偵測 |
| PII 偵測與遮蔽（Sensitive Data Protection） | 同上 | 偵測到常見 PII 時去識別化（遮蔽），不是整段擋掉 |

## 快速開始

```bash
cd ai-onboarding/examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：project_id、location
# 第一次套用建議保持 enforcement_type = INSPECT_ONLY（dry-run）

terraform init
terraform plan
terraform apply
```

套用後會產生一個 Model Armor Template，整合一組 Sensitive Data Protection Inspect + De-identify Template。`enforcement_type` 預設 `INSPECT_ONLY`（只記錄 Finding、不擋流量），觀察一輪 Finding 都是預期內的違規之後，再改成 `INSPECT_AND_BLOCK`——呼應本站 [VPC Service Controls](/security-products/vpc-service-controls) 一貫的先 dry-run、後 enforce 慣例。

完整的變數說明見 [`ai-onboarding/modules/ai_guardrails/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding/modules/ai_guardrails)。

## 需要自行決定的治理事項

以下項目沒有對應的 Terraform 資源，屬於組織治理政策，套用前建議先有答案：

- **AI 用途風險分級**：哪些用途屬於高風險（例如涉及信用審核、招聘篩選、醫療/法律建議），需要額外的人工審核。
- **Model Garden 白名單審核流程**：誰能核准新模型上線、SLA 多長、既有白名單多久複審一次。
- **AI 事故應變**：Prompt Injection 攻擊成功、模型輸出洩漏 PII 等事件，要走哪一條通報路徑、由誰負責、分幾級。
- **GPU/TPU 容量與成本**：Quota/Reservation 由誰申請、誰審核，成本歸屬建議延用 [8.1 節](/governance/tagging)的 Labels 慣例。

## 要不要導入 AI Gateway

AI Gateway（Apigee AI Gateway／Google Cloud API Gateway 的 model routing）處理的是 Token/Rate Limiting、多模型路由、集中套用 Model Armor policy 這些應用層/平台層的問題，不是必裝項目：

| 判斷條件 | 建議 |
| --- | --- |
| 單一應用、單一團隊、只用 Vertex AI 一家模型 | 不需要，Model Armor 直接掛在 Vertex AI 或應用上即可 |
| 多團隊/多應用，需要統一計費、統一稽核 | 需要，Apigee 當強制 ingress |
| 有串接第三方模型（非 Google），或需要 model failover | 需要，這是 Vertex AI 原生機制管不到的範圍 |
| 有 Agentic workload（Gemini Enterprise Agent Platform） | 另外評估 Agent Gateway，跟一般 LLM API Gateway 是不同產品線 |

## 不在這個子專案範圍內

以下項目屬於使用平台的應用/資料團隊該建置的範疇，刻意不涵蓋：

- MLOps CI/CD pipeline、Model Registry 版本控管、Vertex AI Model Monitoring
- Vector DB/RAG pipeline 的技術設計、Agent 應用邏輯本身
- Vertex AI 的 Private Service Connect 網路連線、VPC-SC 涵蓋 `aiplatform.googleapis.com`（可依 [VPC Service Controls](/security-products/vpc-service-controls) 既有方法論自行擴充）

需要 MLOps/Model Registry 這類能力，參考 Google 官方 [genai-mlops-blueprint](https://docs.cloud.google.com/architecture/blueprints/genai-mlops-blueprint)。

完整的模組說明、已知限制與每個預設值背後的理由，見 [`ai-onboarding/README.md`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/ai-onboarding/README.md)。
