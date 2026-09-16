---
title: Retention policy and cost
description: Default log bucket retention periods, the irreversible risk of log bucket locking, and cost-control advice for Data Access logs.
keywords: [log retention, log bucket locking, Data Access log cost]
sidebar_position: 3
---

# 4.3 Retention Policy & Cost

The `_Default` log bucket keeps logs for 30 days by default (adjustable from 1 to 3,650 days). The `_Required` bucket — holding the free, non-disableable Admin Activity and System Event logs — has a fixed 400-day retention that can't be changed, and never incurs a retention charge. Extending retention only affects logs going forward — **logs that have already expired and been purged cannot be recovered** — which means a log sink needs to be set up *before* you need that historical record, not after an incident makes you realise the logs you need have already expired.

If compliance requires that logs can't be tampered with or deleted early, you can turn on [log bucket locking](https://docs.cloud.google.com/logging/docs/buckets):

:::danger
Locking a log bucket is an **irreversible operation** — once locked, the retention period can't be shortened or extended, and the bucket itself can't be deleted until every log inside has satisfied its retention period. That's precisely the point (it stops someone shortening the retention window to destroy evidence), but make absolutely sure the retention period is correct before you apply it — don't lock it and only then discover the period was set too short.
:::

:::danger
Data Access logs — especially for high-traffic services like BigQuery and Cloud Storage — can push your bill well past what you expected; Google's own guidance is that "development environments can usually exclude Data Access logs." A common mistake is hearing "audit compliance" and demanding every service, every environment, and Data Access logging switched on across the board with no differentiation. Confirm scope first with whoever actually needs the record (usually compliance or security), and enable logging only for the services and environments that genuinely need auditing — not everywhere, just for peace of mind.
:::
