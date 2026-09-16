---
title: Assured Workloads（合規限定場景）
description: 特定法規要求（FedRAMP、CJIS、ITAR）下，用 Assured Workloads 把整個 Folder 包進合規套件的做法。
keywords: [Assured Workloads, FedRAMP, CJIS, ITAR, 合規]
sidebar_position: 7
---

# 5.7 Assured Workloads（合規限定場景）

如果業務落在 FedRAMP、CJIS、ITAR 這類特定法規要求（多數企業用不到，遇到再研究），[Assured Workloads](https://docs.cloud.google.com/assured-workloads/docs/overview) 可以把一整個 Folder 包進特定合規套件，自動套用對應的地區限制、加密要求、人員存取限制，底下新建的資源都會自動繼承，不用每個 Project 自己重新設一次。

以上 KMS / Secret Manager / Cloud Armor / Binary Authorization 的實際 Terraform 範例見 [`security-products/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/security-products) 子專案。
