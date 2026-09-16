---
title: 規劃 GCP Organization Policies
description: 用 Organization Policy 在機構、資料夾或專案層級設下治理護欄，並用 Terraform 對照 CIS Benchmark 管理 33 項政策。
keywords: [Organization Policy, org policy, CIS Benchmark, GCP 治理]
sidebar_position: 2
---

# 2.2 規劃 GCP Organization Policies

GCP Organization Policies 主要是讓管理員在機構、資料夾或專案層級設定統一的限制條件（constraints），例如限制資源建立地區、限制對外資料分享、限制可用服務等。政策會自動繼承到 Folder/Project，也能在下層覆寫。簡單說就是幫整個 GCP 環境設下治理護欄，讓團隊在合規範圍內自由運作。

基本上當 GCP Organization 啟用後已經有[預設 Organization Policies](https://docs.cloud.google.com/organization-policy/reference/org-policy-constraints#automatically_enforced_constraints)啟用。如果公司政策需要符合基本的 CIS Benchmark，可以參考 [`organization-policies/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies) 這個 Terraform 子專案：

- [政策中英對照表](https://github.com/terensy/gcp-onboarding-workflow/blob/main/organization-policies/docs/policy_catalog.md) — 依據 [CIS Google Cloud Platform Foundation Benchmark v5.0.0](https://github.com/terensy/gcp-onboarding-workflow/blob/main/organization-policies/references/CIS_Google_Cloud_Platform_Foundation_Benchmark_v5.0.0.pdf) 整理的 33 項政策中英對照表。
- [方法論文件](https://github.com/terensy/gcp-onboarding-workflow/blob/main/organization-policies/docs/methodology.md) — 如何依公司自己的風險與業務需求決定「哪些政策要開、開在哪個層級、值該填什麼」，而不是把 CIS 建議照單全收。
- [Terraform module](https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies) — 讀 `policies_catalog.yaml` 用 `for_each` 產生 `google_org_policy_policy` 資源，可直接 `terraform init/plan/apply` 套用。
