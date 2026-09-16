---
title: Firewall 管理
description: 階層式防火牆政策、Network Firewall Policy 與傳統 VPC Firewall Rules 的差異，以及 micro-segmentation 的基準規則設計。
keywords: [Hierarchical Firewall Policy, Network Firewall Policy, VPC Firewall Rules, micro-segmentation]
sidebar_position: 5
---

# 3.5 Firewall 管理

防火牆規則不是只有一種，Google 目前提供三層，作用範圍跟優先權都不一樣：

| 機制 | 作用範圍 | 特性 |
| --- | --- | --- |
| **階層式防火牆政策**（Hierarchical Firewall Policy） | 掛在 Organization 或 Folder，往下繼承到所有 Project | **下層規則無法覆蓋上層規則**——公司級的安全基準線放這裡，改一次全公司生效 |
| **Network Firewall Policy**（全域／區域） | 掛在單一或多個 VPC | 各 VPC 自己的規則，處理該網路獨有的需求 |
| VPC Firewall Rules（傳統模式） | 單一 VPC | 最早期的機制，Google 自家 Security Foundations Blueprint **已經不用這個**，改用上面兩層 |

![Security Foundations Blueprint 的分層防火牆規則範例](/img/diagrams/security-foundations-example-firewall-rules.svg)

Google 官方 Blueprint 的做法是：階層式防火牆政策掛在每個 Folder，設好 RFC 1918 內部流量、[IAP TCP 轉發](https://docs.cloud.google.com/iap/docs/using-tcp-forwarding)（`35.235.240.0/20`）、Load Balancer 健康檢查來源（`35.191.0.0/16`、`130.211.0.0/22`）這些**全公司都要放行的基本規則**；個別 VPC 才需要的規則另外用 Network Firewall Policy 加。核心原則只有一句話：**預設全部擋掉，只開真的需要的流量**（micro-segmentation），不要反過來預設全開再慢慢補洞。

實際的階層式防火牆政策 Terraform 見 [`network-design/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/network-design) 子專案。
