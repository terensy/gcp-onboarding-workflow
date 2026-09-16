---
title: Binary Authorization
description: Gate container image deployment with attestation signatures, with dry-run and breakglass support for a phased rollout.
keywords: [Binary Authorization, attestation, container deployment gating]
sidebar_position: 6
---

# 5.6 Binary Authorization

A deploy-time gatekeeping mechanism: only container images carrying a valid **attestation** signature can be deployed to GKE or Cloud Run. The typical pattern is requiring an attestation proving the image was "built by an approved CI/CD pipeline," blocking anything pushed manually outside that pipeline. It supports dry-run (log only, block nothing) and breakglass (override the policy in an emergency), making it well suited to the same phased rollout approach as VPC-SC rather than a single hard cutover.
