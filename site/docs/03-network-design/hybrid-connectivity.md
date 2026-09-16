---
title: 混合雲連線
description: Cloud VPN、Dedicated Interconnect、Partner Interconnect、Cross-Cloud Interconnect 的頻寬、SLA 與適用情境比較。
keywords: [Cloud VPN, Dedicated Interconnect, Partner Interconnect, Cross-Cloud Interconnect, 混合雲]
sidebar_position: 2
---

# 3.2 混合雲連線

企業導入 GCP 幾乎一定會有一段時間是「地端 + 雲端並存」，連回地端機房的線路怎麼選，[Google 官方比較](https://docs.cloud.google.com/network-connectivity/docs/how-to/choose-product) 給的判斷原則很單純：

| 方案 | 頻寬 | SLA | 使用情境 |
| --- | --- | --- | --- |
| **Cloud VPN (HA VPN)** | 受 Tunnel 數量限制，頻寬較低 | 99.99%（雙介面）/ 99.9% | 成本敏感、頻寬需求不高，或還在評估階段 |
| **Dedicated Interconnect** | 10 / 100 / 400 Gbps | Google 直接提供 End-to-End SLA | 企業級、需要最高吞吐量，且能自己搞定機房 Colocation |
| **Partner Interconnect** | 50 Mbps ~ 50 Gbps 彈性調整 | 由服務供應商提供 | 企業級連線，但沒有 Colocation 據點 |
| **Cross-Cloud Interconnect** | 依對接雲端而定（AWS/OCI 到 400 Gbps） | 99.99%（跨機房）/ 99.9% | 直接對接另一家公有雲（AWS/Azure/OCI/Alibaba），不透過公開網路 |

:::tip
大原則：便宜方案先上 Cloud VPN，真的要衝量、且合約談得動機房代管，才進場談 Interconnect。不要一開始就簽下昂貴的 Dedicated Interconnect 合約，結果用量連零頭都不到。
:::
