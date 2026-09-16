---
title: 集中式 Log Sink
description: 用組織層級的 Aggregated Sink 把全公司的 log 集中到獨立的 Logging Project，分流到 Log Analytics、Cloud Storage 與 SIEM。
keywords: [Aggregated Sink, Log Sink, Logging Project, SIEM]
sidebar_position: 2
---

# 4.2 集中式 Log Sink

單一 Project 各自留著自己的 log，稽核的人要一個一個 Project 開，公司大了根本查不完。[Google 官方建議](https://docs.cloud.google.com/architecture/landing-zones/decide-security) 用**組織層級的 Aggregated Sink**（`includeChildren = true`），把全公司的 log 集中送到一個獨立的 Logging Project，這個 Project 的管理權限要跟一般 Workload Project 的管理員分開——道理很簡單：能竄改/關閉稽核紀錄的人，不該跟被稽核的人是同一群人。

![Security Foundations Blueprint 的集中式 Logging 架構範例](/img/diagrams/security-foundations-example-logging-structure.svg)

Google 自家 Blueprint 的作法是同時送到三個目的地，各自負責不同用途：

| 目的地 | 用途 |
| --- | --- |
| Log Analytics Bucket（掛 BigQuery Dataset） | 即時查詢、事故發生當下的 Ad Hoc 調查 |
| Cloud Storage Bucket | 長期保存，符合法遵/稽核需求 |
| Pub/Sub Topic | 轉送到外部 SIEM（Splunk、QRadar 等） |

實際的 Aggregated Sink + Data Access Audit Config Terraform 見 [`logging/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/logging) 子專案。
