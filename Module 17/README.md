# Module 17 Assignment: AWS EC2 IAM & Security

## Overview
This repository contains the documentation and proof of work for Module 17 Assignment. 

---

## Task 1: S3 Bucket Creation
- Successfully created an S3 bucket named `ashik-module17-bucket-2026`.
- Uploaded sample test objects into the bucket.
- Screenshot proof included in `screenshots/s3-bucket.png`.

---

## Task 2: IAM Role Configuration (Blocked due to Account Permissions)
- **Status:** Blocked / Permission Restricted
- **Issue:** The provided AWS lab account (`arn:aws:iam::388779989543:user/ashikaslam1111@gmail.com`) does not have IAM creation permissions (`iam:GetAccountSummary`, `iam:CreateRole`, etc.).
- **Evidence:** Attached screenshot (`screenshots/iam-permission-denied.png`) showing explicit Access Denied errors for IAM actions.

---

## Task 3: EC2 Instance & Security Hardening
- Launched an EC2 Instance with proper Security Group rules (Port 22 restricted).
- Applied Linux SSH Hardening (`/etc/ssh/sshd_config`):
  - `PasswordAuthentication no`
  - `PermitRootLogin no`
- Configured UFW Firewall:
  - Default deny incoming, allow outgoing.
  - Allowed SSH (Port 22/tcp).