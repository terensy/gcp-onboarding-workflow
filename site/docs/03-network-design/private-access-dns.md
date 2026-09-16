---
title: 私有存取與 Cloud DNS
description: Private Google Access 與 Private Service Connect 的差異，以及集中式 DNS Hub（DNS Forwarding / DNS Peering）的設計方式。
keywords: [Private Google Access, Private Service Connect, Cloud DNS, DNS Peering, DNS Forwarding]
sidebar_position: 3
---

# 3.3 私有存取與 Cloud DNS

VM 只有內部 IP（呼應 [2.2 節 `compute.vmExternalIpAccess`](/organization-setup/organization-policies) 的政策）要怎麼呼叫 Google API？兩種機制：

- **[Private Google Access](https://docs.cloud.google.com/vpc/docs/private-google-access)**：子網路層級開關，讓內部 IP 也能打到 Google API 的公開端點。設定簡單，但不支援 Regional/Multi-regional endpoint。
- **[Private Service Connect (PSC)](https://docs.cloud.google.com/vpc/docs/private-service-connect)**：用自己 VPC 內的內部 IP 建立端點，流量完全不出 Google 網路。[Google 自家的 Security Foundations Blueprint](https://docs.cloud.google.com/architecture/blueprints/security-foundations/networking) 目前採用的就是 PSC + 私有 DNS zone 這個組合，而不是單純依賴 Private Google Access。

Cloud DNS 部分，多環境/多 VPC 的架構建議規劃一個**集中式 DNS Hub**：地端網域用 **DNS Forwarding** 轉送到地端 DNS Server，Google Cloud 內部各 VPC 之間用 **DNS Peering** 互查（Peering 連線沒辦法轉發 DNS 查詢，這也是為什麼多 VPC 情境需要額外設計 DNS Hub，而不是每個 VPC 各自轉發）。

![Security Foundations Blueprint 的集中式 DNS 架構範例](/img/diagrams/security-foundations-example-dns-setup.svg)
