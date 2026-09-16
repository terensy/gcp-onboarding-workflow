---
title: Secret Manager
description: Use Secret Manager instead of hard-coding passwords and API keys, including version management, tiered IAM access and rotation notifications.
keywords: [Secret Manager, secretAccessor, secrets management]
sidebar_position: 4
---

# 5.4 Secret Manager

Replaces passwords and API keys hard-coded into source code or config files. [Secret Manager](https://docs.cloud.google.com/secret-manager/docs/overview) versions secret payloads — code can pin a specific version or follow `latest` — and splits access into three tiers: `secretAccessor` (read the payload only, for applications), `secretVersionManager` (manage versions without reading the payload), and `admin` (full control). All access is written to Cloud Audit Logs.

Rotation works as "Secret Manager handles the scheduled notification (via Pub/Sub); you write the actual rotation logic yourself" — it won't automatically change a database password and write the new value back for you. That automation still has to be implemented separately, typically as a Cloud Run or Cloud Functions handler triggered by the Pub/Sub event.
