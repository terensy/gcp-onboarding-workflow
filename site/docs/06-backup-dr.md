---
title: 備份與災難復原策略
description: 原生服務內建備份機制 vs. Backup and DR Service 的取捨，以及 RPO/RTO 規劃的成本邏輯。
keywords: [Backup and DR, RPO, RTO, 災難復原, Persistent Disk 快照]
sidebar_position: 6
---

# 6. 備份與災難復原策略

「有備份」跟「備份真的救得回來」是兩件事——這裡只講架構層面的基本盤，實際的備援頻率、保留天數要看業務需求另外訂。

## 原生服務內建的備份機制

多數情況這樣就夠用，不用一開始就上額外的產品：

- **Persistent Disk**：[排程快照](https://docs.cloud.google.com/compute/docs/disks/scheduled-snapshots)，掛在 Disk 資源上設定，免另外裝東西，但**快照可以被任何有權限的人手動刪掉**，沒有防竄改機制。
- **Cloud SQL**：預設就有自動備份＋Point-in-time Recovery，還原時會還原成一個**新的執行個體**，不是原地覆蓋。
- **GKE**：[Backup for GKE](https://docs.cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/concepts/backup-for-gke) 是獨立的 Add-on（不算在 Backup and DR Service 底下），備份 Kubernetes 資源設定跟 PVC 資料。

## Backup and DR Service

上面那些原生機制各管各的，沒有統一的政策管理跟報表。如果需要跨服務的集中備份政策，或法遵要求備份**連管理員都不能提早刪除**（防勒索軟體/內部威脅），[Backup and DR Service](https://docs.cloud.google.com/backup-disaster-recovery/docs) 的 Backup Vault 提供的是真正的 WORM（一次寫入、多次讀取）保護——設定的最短保留天數內，連 Google 自己都刪不掉。這是原生快照機制做不到的等級，代價是要多一個產品、多一筆費用。

## RPO / RTO 規劃

:::tip
先跟業務單位要一個數字，再回頭設計架構，不要反過來——[Google 官方原文](https://docs.cloud.google.com/architecture/dr-scenarios-planning-guide) 講得很清楚：RTO/RPO 設得越小，架構成本越高。「當然是希望零停機、零遺失」聽起來很合理，但每多縮短一分鐘 RTO、每多壓低一筆 RPO，換算下來都是要多花的錢跟維運複雜度。先把 RPO/RTO 的數字釘死、寫進文件，之後才有辦法回頭檢視架構有沒有真的達標，不然「零停機」只會是一句沒有人負責兌現的口號。
:::

多 Region 的容錯，可以善用 Google 網路本身的全球分散架構跟跨 Region 的資料複製，把單一 Region 故障的影響降到最低，細節見 [Architecting disaster recovery for cloud infrastructure outages](https://docs.cloud.google.com/architecture/disaster-recovery)。
