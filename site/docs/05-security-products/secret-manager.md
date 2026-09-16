---
title: Secret Manager
description: 用 Secret Manager 取代寫死在程式碼裡的密碼與 API Key，含版本管理、IAM 存取分層與輪替通知機制。
keywords: [Secret Manager, secretAccessor, 密鑰管理]
sidebar_position: 4
---

# 5.4 Secret Manager

取代寫死在程式碼/設定檔裡的密碼、API Key。[Secret Manager](https://docs.cloud.google.com/secret-manager/docs/overview) 用版本管理密文，程式可以釘住特定版本或跟著 `latest`；權限分三層：`secretAccessor`（只能讀密文內容，給應用程式用）、`secretVersionManager`（能管版本但讀不到內容）、`admin`（完整管理），存取都會進 Cloud Audit Log。

輪替機制是「Secret Manager 負責排程通知（Pub/Sub），實際輪替邏輯要自己寫」——它不會自動去改資料庫密碼再回填，那段自動化還是要靠 Cloud Run/Cloud Functions 接 Pub/Sub 事件自己實作。
