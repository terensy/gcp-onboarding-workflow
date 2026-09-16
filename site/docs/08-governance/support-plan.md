---
title: Google Cloud Support Plan
description: Basic/Standard/Enhanced/Premium 四個 Support Plan 的費用、P1 回應時間與 TAM 涵蓋比較，以及正式環境該選哪個等級。
keywords: [Google Cloud Support, Support Plan, TAM, P1 SLA]
sidebar_position: 2
---

# 8.2 Google Cloud Support Plan

| Tier | 費用（美元 USD） | P1（重大事故）回應時間 | 24/7 涵蓋 | 專屬 TAM |
| --- | --- | --- | --- | --- |
| Basic | 免費 | 不提供 Case 支援 | 否 | 否 |
| Standard | $29/月 或月費用 3%（取高者） | **不提供**（P1 這個等級在 Standard 直接不存在） | 否，僅上班時間 | 否 |
| Enhanced | $100/月起，依用量遞減% | 1 小時 | 是（限高/重大影響事故） | 否（付費加購 Technical Account Advisor） |
| Premium | $15,000/月起，依用量遞減% | **15 分鐘** | 是 | 是，指定專屬 TAM |

:::danger
Standard tier **完全沒有 P1 等級**，不是「回應比較慢」，是「這個等級的事故類型在 Standard 合約裡根本不存在」。選 Support Plan 如果只看「有沒有中文窗口」「多少錢」而選了最便宜的 Standard，正式環境半夜掛掉才會發現：打開 Case 只能等上班時間，而系統當機這種等級的事故根本不在 Standard 的服務範圍內。**正式環境的底線是 Enhanced**（Google 自己的定位也是給正式環境用），Premium 才有 15 分鐘 SLA 跟專屬 TAM，留給真的 Mission-critical、停機一分鐘就是巨額損失的服務。
:::
