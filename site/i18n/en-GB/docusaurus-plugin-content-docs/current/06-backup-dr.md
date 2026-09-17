---
title: 6. Backup & disaster recovery strategy
description: Native per-service backup features versus Backup and DR Service, and the cost logic behind RPO/RTO planning.
keywords: [Backup and DR, RPO, RTO, disaster recovery, Persistent Disk snapshots]
sidebar_position: 6
---

# 6. Backup & Disaster Recovery Strategy

"Having a backup" and "the backup actually being recoverable" are two different things — this section only covers the architectural baseline; actual backup frequency and retention periods need to be set against real business requirements.

## Native per-service backup features

These are sufficient in most cases, and you don't need to reach for an extra product from day one:

- **Persistent Disk**: [scheduled snapshots](https://docs.cloud.google.com/compute/docs/disks/scheduled-snapshots), configured directly on the disk resource with nothing extra to install — but **anyone with sufficient permission can manually delete a snapshot**, since there's no tamper-protection built in.
- **Cloud SQL**: automated backups plus point-in-time recovery are on by default; restoring always creates a **new instance** rather than overwriting the original in place.
- **GKE**: [Backup for GKE](https://docs.cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/concepts/backup-for-gke) is a separate add-on (it isn't part of Backup and DR Service), backing up Kubernetes resource configuration and PVC data.

## Backup and DR Service

The native mechanisms above are each managed independently, with no unified policy management or reporting. If you need centralised backup policy across services, or compliance requires backups that **even administrators can't delete early** (protecting against ransomware or insider threats), [Backup and DR Service](https://docs.cloud.google.com/backup-disaster-recovery/docs)'s Backup Vault provides genuine WORM (write-once, read-many) protection — within the configured minimum retention period, not even Google itself can delete the data. That's a level native snapshotting can't reach, at the cost of an additional product and an additional line item.

## RPO / RTO planning

:::tip
Get a number from the business first, then design the architecture around it — not the other way round. [Google's own guidance](https://docs.cloud.google.com/architecture/dr-scenarios-planning-guide) is blunt about this: the smaller your RTO/RPO targets, the more the architecture costs. "Obviously we want zero downtime and zero data loss" sounds reasonable in a requirements interview, but every minute you shave off RTO and every transaction you shave off RPO translates directly into more spend and more operational complexity. Pin the RPO/RTO numbers down in writing early, so you have something concrete to measure the architecture against later — otherwise "zero downtime" is just a slogan nobody's actually on the hook for.
:::

For multi-region resilience, lean on Google's own globally distributed network and cross-region data replication to minimise the impact of a single-region outage — see [Architecting disaster recovery for cloud infrastructure outages](https://docs.cloud.google.com/architecture/disaster-recovery) for the detail.
