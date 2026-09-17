---
title: AI 基礎設施導入
description: 在既有企業級導入基礎上，加裝 AI/ML workload（Vertex AI、Gemini Enterprise）需要的治理與護欄——Model Garden 白名單、Model Armor 語義層防護、Sensitive Data Protection，部分項目已有可用的 Terraform。
keywords: [AI onboarding, Vertex AI, Gemini Enterprise, Model Armor, Sensitive Data Protection, GCP AI governance]
sidebar_position: 1
---

# 10. AI 基礎設施導入

如果貴公司的 GCP 導入範圍包含 AI/ML workload（Vertex AI、Gemini Enterprise 為主），前面章節的治理框架（Organization Policies、IAM、網路、Logging、安全性產品）大部分可以直接沿用——AI workload 本質上還是 workload，不需要另立一套獨立的治理分類。這一章記錄的是「AI 特有」、傳統章節補不到的部分，對應 [`ai-onboarding/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding) 這個 Terraform 子專案。

:::tip
這個子專案**仍在建置中**。以下標示「✅ 已實作」的項目已有 Terraform 並通過 `terraform validate`；其餘項目仍是規劃階段。動手前建議先看 [`ai-onboarding/README.md`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/ai-onboarding/README.md) 的「現況總覽」確認每一項的實際狀態。
:::

## 必做 vs 選擇性

不管起始狀態是什麼，以下項目建議在導入的第一天就內建預設值：

| 項目 | 狀態 | 說明 |
| --- | --- | --- |
| Org Policy AI 基準集 | ✅ 已實作 | `constraints/vertexai.allowedModels`（Model Garden 白名單）、`constraints/iam.automaticIamGrantsForDefaultServiceAccounts`（關閉 default SA 自動授權），已加入 [Organization Policies](/organization-setup/organization-policies) 的 catalog |
| Model Armor | ✅ 已實作 | Prompt Injection/Jailbreak、惡意 URL 偵測，`enforcement_type` 預設 `INSPECT_ONLY`（dry-run），觀察一輪後再改成 `INSPECT_AND_BLOCK` |
| Sensitive Data Protection（PII） | ✅ 已實作 | 偵測到 PII 預設去識別化（遮蔽），不是整段擋掉；跟 Model Armor 用同一個 Terraform module |
| AI 用途風險分級與審核政策 | 📝 文件層 | 誰能核准新的 AI use case 上線、Model Garden 白名單多久複審一次——純治理政策，沒有對應的 GCP 資源 |
| AI 事故應變 Runbook | 📝 文件層 | Prompt Injection 攻擊成功、模型洩漏 PII 等事件的分類與通報路徑 |
| IAM 進階群組分工、AI 專屬 CMEK、VPC-SC 擴充、PSC 網路連線、進階資料治理、GPU/TPU 容量規劃 | ⬜ 選擇性 | 依團隊規模、法遵需求另外評估 |
| AI Gateway（Apigee）／Agent Gateway | 🔀 條件式 | 只有多團隊/多應用、需要串接第三方模型，或有 Agentic workload 時才需要，見下方決策表 |

## Model Armor + Sensitive Data Protection 快速開始

```bash
cd ai-onboarding/examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：project_id、location
# enforcement_type 建議先保持 INSPECT_ONLY（dry-run）

terraform init
terraform plan
terraform apply
```

套用後會產生：

- 一個 Model Armor Template（Prompt Injection/Jailbreak、惡意 URL 偵測，整合下面的 SDP Template）
- 一組 Sensitive Data Protection Inspect + De-identify Template（預設偵測 Email、電話、信用卡卡號、姓名、地址；身分證字號另外用 regex 做格式比對，不是官方檢查碼驗證，套用前建議跟法遵確認是否符合實際需求）

完整的變數說明、預設值取捨見 [`ai-onboarding/modules/ai_guardrails/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding/modules/ai_guardrails)。

## AI Gateway 該不該導入？

AI Gateway（Apigee AI Gateway／Google Cloud API Gateway 的 model routing）解決的是 Token/Rate Limiting、多模型路由、集中套用 Model Armor policy 這些應用層/平台層的問題，不是必裝模組：

| 判斷條件 | 建議 |
| --- | --- |
| 單一應用、單一團隊、只用 Vertex AI 一家模型 | 不需要，Model Armor 直接掛在 Vertex AI 或應用上即可 |
| 多團隊/多應用，需要統一計費、統一稽核 | 需要，Apigee 當強制 ingress |
| 有串接第三方模型（非 Google），或需要 model failover | 需要，這是 Vertex AI 原生機制管不到的範圍 |
| 有 Agentic workload（Gemini Enterprise Agent Platform） | 另外評估 Agent Gateway，跟一般 LLM API Gateway 是不同產品線 |

## 明確排除範圍

以下項目刻意不在這個子專案範圍內，屬於使用平台的應用/資料團隊該建置的範疇：

- MLOps CI/CD pipeline、Model Registry 版本控管
- Vertex AI Model Monitoring（訓練-推論偏移、預測漂移偵測）
- Vector DB/RAG pipeline 的技術設計
- Agent 應用邏輯本身（工具串接、prompt engineering）

完整的設計脈絡、Baseline 預設值取捨、Responsible AI 治理政策草案、事故應變雛形，見 [`ai-onboarding/README.md`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/ai-onboarding/README.md)。
