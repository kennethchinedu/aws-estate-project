# Test log

Every test: prediction written **before** running. Where I didn't predict, it says so.

| # | Date | Test | Principal | Prediction | Actual result | Deciding policy | Notes |
|---|---|---|---|---|---|---|---|
| 1 | 2026-10-16 | `ec2:DescribeInstances` in us-east-1 | Admin (SSO), Log Archive | none, found by accident | Deny | SCP `GRREGIONDENY` (`p-f7qhtfbh`) | EC2 Global View queries every region; London and Ireland worked |
| 2 | 2026-10-16 | `cloudtrail:StopLogging` on a fake trail, before the SCP | Admin (SSO), payments-dev | Allow | `TrailNotFoundException` (authorized) | identity policy `AdministratorAccess` | control test; fake name so nothing real is touched |
| 3 | 2026-10-16 | same, after `deny-cloudtrail-tampering` on Nonprod | Admin (SSO), payments-dev | Deny, `p-zgjhqban` | Deny | SCP `p-zgjhqban` | error names the SCP |
| 4 | 2026-10-16 | `s3:ListAllMyBuckets`, before `deny-root` | root, payments-dev | Allow | Allow (0 buckets) | no SCP matches | control test |
| 5 | 2026-10-16 | same, after `deny-root` on Nonprod | root, payments-dev | Deny, `deny-root` | Deny | SCP `p-f3i6s04o` | console message is generic; CloudTrail `errorMessage` names the SCP |
| 6 | 2026-10-16 | same, after `deny-root` | Admin (SSO), payments-dev | Deny (wrong) | Allow | `deny-root` condition only matches `…:root` | proves the SCP hits root only |
| 7 | 2026-10-17 | detective controls enabled on Workloads reach the accounts | — | Config rules in payments-dev | 0 rules | Control Tower: nested OUs don't inherit detective/proactive controls | moved to Prod + Nonprod; payments-dev now has 3 rules |
| 8 | 2026-10-18 | PR plan assumes `ci-plan` (first run) | GitHub, PR #1 | Allow | Deny (`AssumeRoleWithWebIdentity`) | `ci-plan` trust policy `sub` | repo uses immutable subjects (`owner@id/repo@id`); `sub` updated |
| 9 | 2026-10-18 | PR plan (second run) | `ci-plan` | Allow | Deny (`controltower:GetEnabledBaseline`) | identity policy: `ReadOnlyAccess` has no Control Tower reads | added `controltower:Get*`/`List*` |
| 10 | 2026-10-18 | PR plan (third run) | `ci-plan` | Allow | Allow, "No changes" | — | |
| 11 | 2026-10-18 | feature branch assumes `ci-apply` | GitHub, push to `test/oidc-deny` | Deny at "Configure AWS credentials" | Deny | `ci-apply` trust policy `sub` (main only) | red job = pass; identity step skipped |
| 12 | 2026-10-18 | pull request assumes `ci-apply` | GitHub, PR #2 | none | Deny | `ci-apply` trust policy `sub` | unmerged code can't get the apply role |
| 13 | 2026-10-18 | direct push to `main` | repo admin | Reject | Rejected, `GH013` | ruleset `protect-b` (PR required, admin bypass PR-only) | |
| 14 | 2026-10-18 | apply from `main` after merging PR #3 | `ci-apply` | Allow, 0 changes | Allow, 0 added / 0 changed / 0 destroyed | — | first CI apply; plan job skipped |
