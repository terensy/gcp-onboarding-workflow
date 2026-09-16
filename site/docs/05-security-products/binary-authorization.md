---
title: Binary Authorization
description: 用 Attestation 簽章證明把關容器映像檔部署，支援 Dry-run 與 Breakglass 的分階段導入方式。
keywords: [Binary Authorization, Attestation, 容器部署把關]
sidebar_position: 6
---

# 5.6 Binary Authorization

部署時的把關機制：只有帶著**簽章證明（Attestation）**的容器映像檔才能部署到 GKE/Cloud Run。典型用法是要求「必須有『通過核准的 CI/CD Pipeline 建置』這個簽章」，擋掉任何繞過正規 Pipeline、直接手動推上去的映像檔。支援 Dry-run（只記錄不擋）跟 Breakglass（緊急時刻可覆蓋政策），適合像 VPC-SC 一樣分階段導入，不用一次到位。
