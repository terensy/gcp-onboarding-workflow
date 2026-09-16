---
title: Cloud KMS (CMEK)
description: When you need Customer-Managed Encryption Keys, the cost differences between the three key protection levels, and enforcing CMEK with Organization Policy.
keywords: [Cloud KMS, CMEK, Customer-Managed Encryption Keys, HSM]
sidebar_position: 3
---

# 5.3 Cloud KMS (CMEK)

By default, GCP encrypts all data at rest with a key Google manages itself — the customer can't see or control it. If compliance requires the customer to control the key's own lifecycle (rotation schedule, who can use it, after-the-fact auditing), that's when you need [CMEK](https://docs.cloud.google.com/kms/docs/cmek) (Customer-Managed Encryption Keys) — it's an option you switch on when compliance demands it, not a default every resource needs.

Keys come in three protection levels with meaningfully different costs: software (available in most regions, cheapest), Cloud HSM (FIPS 140-2 Level 3, dedicated hardware), and Cloud EKM (the key material stays in an external KMS that Google never touches at all, but rotation has to be coordinated manually with the external system).

:::note
Rotating a key does **not** automatically re-encrypt data that was already encrypted, and old key versions don't automatically expire either — old versions have to stay around to decrypt old data; genuinely retiring them is a separate manual step. This is often mistakenly assumed to mean "rotation instantly invalidates the old key."
:::

To force specific services to use CMEK, use the Organization Policy constraints `constraints/gcp.restrictNonCmekServices` (blocks creating resources that aren't CMEK-protected) alongside `constraints/gcp.restrictCmekCryptoKeyProjects` (restricts keys to only come from a designated KMS project) — evaluate these using the [organization-policies methodology](https://github.com/terensy/gcp-onboarding-workflow/blob/main/organization-policies/docs/methodology.md) before adding them to that sub-project's catalogue.
