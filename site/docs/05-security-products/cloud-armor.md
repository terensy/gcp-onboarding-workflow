---
title: Cloud Armor
description: Cloud Armor 的 WAF 與 DDoS 防護機制、OWASP Core Rule Set、Rate Limiting，以及 Enterprise 版的階層式安全政策。
keywords: [Cloud Armor, WAF, DDoS, OWASP Core Rule Set, Rate Limiting]
sidebar_position: 5
---

# 5.5 Cloud Armor

架在 Load Balancer 前面的 [WAF + DDoS 防護](https://docs.cloud.google.com/armor/docs/cloud-armor-overview)。

![Cloud Armor 在網路邊界的執行位置](/img/diagrams/cloud-armor-edge-enforcement.svg)

L3/L4 的 DDoS 防護是自動、免費、不用設定就有；L7（例如 HTTP Flood）需要另外設定 Security Policy，可以套用 OWASP Core Rule Set 當預設 WAF 規則（有 0~4 級敏感度可調，太敏感容易誤擋正常流量），也能設定 Rate Limiting。付費的 Enterprise 版本額外提供 Adaptive Protection（ML 自動偵測攻擊模式）、威脅情資、以及**階層式的安全政策**（可以在 Org/Folder 層級訂一個基準線，各專案在上面疊加自己的規則）。
