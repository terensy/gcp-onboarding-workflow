---
title: 保留政策與費用
description: Log Bucket 的預設保留天數、Log Bucket Locking 的不可逆風險，以及 Data Access log 的費用控管建議。
keywords: [Log retention, Log Bucket Locking, Data Access log 費用]
sidebar_position: 3
---

# 4.3 保留政策與費用

`_Default` Log Bucket 預設保留 30 天（可調 1~3650 天），`_Required` Bucket（放 Admin Activity/System Event 這些免費、關不掉的 log）固定保留 400 天、不能改、也不收費。延長保留只對「之後」的 log 有效，**已經過期被清掉的 log 沒辦法救回來**——這代表 Log Sink 要在「需要那份歷史紀錄之前」先設好，不是等事故發生才想到要調 log，那時候能查的 log 早就過期了。

如果法遵要求 log 不能被竄改/提早刪除，可以對 Log Bucket 開啟 [Log Bucket Locking](https://docs.cloud.google.com/logging/docs/buckets)：

:::danger
Lock 一個 Log Bucket 是**不可逆的操作**——鎖定之後保留天數不能再改短也不能改長，Bucket 裡的資料在保留期滿之前連 Bucket 本身都刪不掉。這正是它的設計目的（防止有心人縮短保留天數來湮滅證據），但套用前務必先確認保留天數設對，不要鎖了才發現天數設短了。
:::

:::danger
Data Access log（尤其是 BigQuery、Cloud Storage 這種高流量服務）開下去帳單可能會超出預期，Google 官方自己都建議「開發環境通常可以排除 Data Access log」。常見的錯誤做法是聽到「稽核合規」四個字就要求全部服務、全部環境、Data Access 通通打開——先跟需要這份紀錄的人（通常是法遵/資安）確認範圍，只開真的需要稽核的服務和環境，不是為了「安心」兩個字就無差別全開。
:::
