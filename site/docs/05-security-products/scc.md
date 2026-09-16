---
title: Security Command Center (SCC)
description: SCC 的 Standard/Premium/Enterprise 三個 Tier 比較，以及為什麼建議在 Organization 層級啟用。
keywords: [Security Command Center, SCC, Security Health Analytics, Event Threat Detection]
sidebar_position: 1
---

# 5.1 Security Command Center (SCC)

集中式的資安風險儀表板：資產盤點、[錯誤設定偵測（Security Health Analytics）](https://docs.cloud.google.com/security-command-center/docs/concepts-security-health-analytics)、漏洞掃描、[威脅偵測（Event Threat Detection）](https://docs.cloud.google.com/security-command-center/docs/concepts-event-threat-detection-overview)、合規狀態對照（CIS/NIST/HIPAA/PCI-DSS）都在同一個地方看。

![Security Foundations Blueprint 使用的核心安全服務](/img/diagrams/security-foundations-key-services.svg)

| Tier | 費用 | 涵蓋範圍 |
| --- | --- | --- |
| **Standard** | 免費 | 基本錯誤設定/威脅偵測，僅 GCP |
| **Premium** | 付費（用量制或訂閱） | 完整 Security Health Analytics、漏洞評估（含 AWS 掃描）、完整威脅偵測、合規對照、Attack Path Simulation |
| Enterprise | 付費 | 多雲 CNAPP、SIEM/SOAR 整合——Google 已宣布 2027/5/21 停用，屆時自動併入 Premium，新導入案不建議選這個 |

[Google 官方建議在 Organization 層級啟用 SCC](https://docs.cloud.google.com/security-command-center/docs/activate-scc-overview)，這樣才能一次涵蓋底下所有 Folder/Project，而不是每個 Project 各自啟用、各自有各自的視野死角。偵測到的 Finding 可以用 Pub/Sub 轉出去給既有的 SIEM/SOAR（Splunk、QRadar、Google SecOps 等）。
