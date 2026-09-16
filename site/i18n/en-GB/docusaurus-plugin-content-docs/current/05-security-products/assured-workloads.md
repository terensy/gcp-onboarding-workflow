---
title: Assured Workloads (compliance-specific scenarios)
description: For specific regulatory requirements (FedRAMP, CJIS, ITAR), Assured Workloads wraps an entire folder in a compliance package.
keywords: [Assured Workloads, FedRAMP, CJIS, ITAR, compliance]
sidebar_position: 7
---

# 5.7 Assured Workloads (Compliance-Specific Scenarios)

If your business falls under a specific regulatory regime like FedRAMP, CJIS or ITAR (most companies won't need this — look into it if and when it applies), [Assured Workloads](https://docs.cloud.google.com/assured-workloads/docs/overview) can wrap an entire folder in a given compliance package, automatically applying the matching regional restrictions, encryption requirements and personnel-access restrictions. Any resource created underneath inherits them automatically, so you don't have to re-configure each project from scratch.

Working Terraform examples for KMS / Secret Manager / Cloud Armor / Binary Authorization live in the [`security-products/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/security-products) sub-project.
