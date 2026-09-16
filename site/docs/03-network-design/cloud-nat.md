---
title: Cloud NAT
description: 關閉 VM 外部 IP 之後，用 Google 全代管、分散式的 Cloud NAT 讓 VM 仍能出網下載套件更新。
keywords: [Cloud NAT, GCP 出網, 分散式 NAT]
sidebar_position: 4
---

# 3.4 Cloud NAT

`compute.vmExternalIpAccess` 政策（見 [Organization Policies](/organization-setup/organization-policies)）關掉 VM 的外部 IP 之後，VM 要怎麼連到外面下載套件更新？答案是 [Cloud NAT](https://docs.cloud.google.com/nat/docs/overview)——它是 Google 全代管、分散式的 NAT，不是掛一台 NAT VM 當單點故障，只需要照需要出網的 Region 開 Gateway，並把 Logging 至少開到 `ERRORS_ONLY`，方便事後查連線失敗的原因。
