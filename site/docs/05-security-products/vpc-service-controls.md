---
title: VPC Service Controls (VPC-SC)
description: VPC-SC 如何防止資料外洩、核心概念（Service Perimeter、Access Level、Ingress/Egress Rule），以及官方建議的 Dry-run 到 Enforce 導入流程。
keywords: [VPC Service Controls, VPC-SC, Service Perimeter, Access Level, Dry-run]
sidebar_position: 2
---

# 5.2 VPC Service Controls (VPC-SC)

IAM 管的是「誰能呼叫這個 API」，VPC-SC 管的是「資料能不能被搬到這個邊界之外」——就算 IAM 設定不小心開太大、或是有人的帳密外洩，VPC-SC 的邊界（Service Perimeter）還是能擋住資料被複製到邊界外的行為。[Google 官方原文](https://docs.cloud.google.com/vpc-service-controls/docs/overview)：「建議同時使用 VPC Service Controls 和 IAM 做縱深防禦」——這是疊加的防線，不是拿來取代 IAM 的。

![VPC Service Controls 基本概念：Perimeter 內外的存取控制](/img/diagrams/vpc-sc-service-perimeter.png)

## 核心概念

- **Service Perimeter**：把一群 Project 圍起來，預設全擋跨越邊界的存取。
- **Access Level**：用 IP 範圍/裝置政策/身分白名單，定義誰可以從邊界外進來。
- **Ingress / Egress Rule**：比 Perimeter Bridge 更細緻的例外機制——Google 官方明講**不建議用多個 Bridge 或 DMZ Perimeter 這種複雜設計**，能用 Ingress/Egress Rule 解決就不要疊 Bridge。

:::warning
VPC-SC 設錯是會**直接讓正式環境掛掉**的等級，不是「設定錯了 apply 會報錯」這種安全失敗，而是「套用當下看起來成功，結果 CI/CD 或跨 Project 的資料管線全部斷線」。Google 官方點名最常被忘記放進邊界的：**Terraform/Jenkins 這類自動化工具的 Service Account**、地端經 VPN/Interconnect 連進來的流量（連線會被算在連線所在的那個 VPC 專案，包含 Shared VPC 的 Host Project）、以及 Cloud Logging 匯出用的 Google 代管服務帳戶。套用前**沒有先盤點過這些例外**，等於是拿正式環境的穩定性去賭。
:::

## 建議的導入流程

因為風險等級這麼高，[Google 官方的建議流程](https://docs.cloud.google.com/vpc-service-controls/docs/enable) 是：

1. 先盤點所有合法的存取模式（官方甚至提供[現成的盤點範本 PDF](https://cloud.google.com/static/solutions/vpc-service-controls-enterprise-best-practices-use-cases-template.pdf)）
2. 用 **Dry-run 模式**建立邊界（只記錄違規、不擋流量）
3. 讓各團隊照平常方式跑一遍所有 workload
4. 分析 Dry-run 記下來的違規紀錄
5. 確認每一筆都是預期內的例外之後才真的 Enforce

Google 自家的 Security Foundations Blueprint 預設也**只部署 Dry-run 模式**，enforce 與否留給每個組織自己評估。

:::danger
法遵稽核前一週才想到要上 VPC-SC、要求「這週就要 Enforce」，是最常見也最危險的捷徑。上面那個盤點＋Dry-run 的流程跳過任何一步，代表拿正式環境當白老鼠。Dry-run 觀察期要抓多長，得看業務的使用模式有多複雜，沒有「這週上線」這種捷徑。
:::

完整的 Perimeter 設計方式、Dry-run 到 Enforce 的操作細節，見 [`security-products/docs/vpc-service-controls.md`](https://github.com/terensy/gcp-onboarding-workflow/blob/main/security-products/docs/vpc-service-controls.md)。
