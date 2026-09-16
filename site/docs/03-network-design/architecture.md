---
title: 網路架構設計
description: GCP Landing Zone 的 4 種網路拓樸選項比較——Shared VPC、Hub-and-Spoke、Private Service Connect，以及 NCC/Peering/VPN 的取捨。
keywords: [Shared VPC, Hub-and-Spoke, Network Connectivity Center, GCP 網路設計]
sidebar_position: 1
---

# 3.1 網路架構設計

網路是所有 Landing Zone 決策裡最難事後回頭改的一塊——IAM 角色設錯了改一行 binding 就好，網路架構設計錯了往往要牽動所有已經在跑的 Workload 重新規劃 CIDR、重新接防火牆規則，甚至要約時間半夜切網段。建議照 [Google 官方 Landing Zone 網路設計指南](https://docs.cloud.google.com/architecture/landing-zones/decide-network-design) 的決策框架，先想清楚再動手，不要先建一個 VPC 再說。

Google 官方列出 4 種 Landing Zone 網路拓樸，依「團隊要多少自主權」與「要不要集中管控」排列：

| 選項 | 做法 | 適用情境 |
| --- | --- | --- |
| **選項 1：每個環境一個 Shared VPC**（**Google 官方預設建議，多數情況適用**） | Host Project 集中管理網路，Service Project 掛進來共用 | 想要集中控管防火牆/路由，架構單純好維護 |
| 選項 2：Hub-and-Spoke + 集中式網路設備（NVA） | Hub VPC 跑第三方防火牆設備，Spoke 之間的流量都繞經 Hub | 法遵要求 Layer-7 檢查，或既有的 NVA 廠商合約用不掉 |
| 選項 3：Hub-and-Spoke（無設備） | Hub 只負責共用的地端連線，環境之間互相隔離 | 想讓各環境獨立、又要共用同一條專線/VPN |
| 選項 4：Private Service Connect 生產者/消費者模式 | 每個 VPC 各自獨立，只用 PSC 端點暴露特定服務 | 團隊要完全自主，服務只透過明確定義的端點溝通 |

![Landing Zone 網路架構：每個環境一個 Shared VPC](/img/diagrams/network-design-option1-shared-vpc.svg)

:::note
沒有特殊理由的話，直接選**選項 1**。多數導入案並沒有那麼特殊，先選最簡單、Google 自己都說「多數情況適用」的方案，不要一開始就把架構往最複雜的方向設計——複雜的架構是拿來解決真的遇到的問題，不是拿來證明團隊很懂雲端。
:::

如果環境之間需要互通（選項 2/3），Hub-and-Spoke 實際的連線機制還有三種可以選，各有取捨：

![Hub-and-Spoke 拓樸：以 Network Connectivity Center 實作](/img/diagrams/network-hub-spoke-ncc.svg)

| 機制 | 頻寬 | Spoke 之間可否直接互通（Transitive） | 備註 |
| --- | --- | --- | --- |
| **Network Connectivity Center (NCC)** | 完整頻寬 | 可以 | 現行 Google 建議的做法，支援 Star / Mesh 拓樸 |
| VPC Network Peering | 完整頻寬 | 不行（non-transitive） | 有 Peering 數量上限，規模大了會卡到配額 |
| Cloud VPN | 受限於 Tunnel 頻寬 | 可以 | 頻寬不夠可以疊加 Tunnel，但複雜度跟成本也跟著疊加 |

實際的 Shared VPC + 階層式防火牆政策 Terraform 見 [`network-design/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/network-design) 子專案。
