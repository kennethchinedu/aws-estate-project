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
| 15 | 2026-10-18 | open a shell on the private server (no public IP, no SSH, no inbound rules) | Admin (SSO), payments-dev | none | Allow, Session Manager shell as `ssm-user` | instance role `AmazonSSMManagedInstanceCore`; agent connects out via NAT | |
| 16 | 2026-10-18 | server uploads to the endpoint-locked bucket | server role, via the S3 gateway endpoint | Allow | Allow | bucket Deny doesn't match (`aws:SourceVpce` = endpoint); role allows `s3:PutObject` | the endpoint only removes the Deny; the Allow comes from the role |
| 17 | 2026-10-18 | read the bucket from a laptop | management SSO (another account) | Deny | Deny, 403 | no Allow for other accounts (and the endpoint Deny) | same-account Admin run not done, so this doesn't isolate the endpoint lock |
| 18 | 2026-10-18 | server reaches the internet | server, via the NAT | Allow | Allow, `HTTP/2 200` | private route `0.0.0.0/0` → NAT; SG allows 443 out | |
| 19 | 2026-10-18 | deny-all NACL on the private subnets | server (background logger) | Deny, as timeouts | `internet=000FAIL`, then a 2-minute gap; normal after removal | NACL with no rules (implicit deny-all) | timeout = network; CLI retries hid the S3 outage (`s3=ok`) |
| 20 | 2026-10-18 | server deletes its own object | server role, via the endpoint | none | Deny, `AccessDenied` | identity policy: no `s3:DeleteObject` (implicit) | least privilege; message says "no identity-based policy allows" |
| 21 | 2026-10-24 | test server reaches the internet (NAT off) | server, private subnet | none | `curl` → `000`, timeout | no route out: no NAT gateway, no 0.0.0.0/0 on the private route table |  |
| 22 | 2026-10-24 | resolve `api.ecr.eu-west-2.amazonaws.com` inside the VPC | server | none | `10.20.1.23`, `10.20.2.224` | interface endpoint `private_dns_enabled` | one ENI per AZ; the laptop resolves the same name to public IPs |
| 23 | 2026-10-24 | `aws sts get-caller-identity` from the server | server role | none | FAIL (connect timeout) | no `sts` endpoint and no NAT | every AWS API the workload calls needs its own endpoint |
| 24 | 2026-10-24 | Session Manager command on the server without NAT | Admin (CT execution role) | none | `send-command` Success | `ssm`, `ssmmessages`, `ec2messages` endpoints |  |
| 25 | 2026-10-24 | server → internal ALB `/` | server | none | `302` → `/login/` | ALB SG (private subnet CIDRs) → task SG (from ALB SG); target healthy | CloudFront off: account not yet verified for CloudFront |
| 26 | 2026-10-24 | PyGoat login page through the ALB | server | none | `<title>OWASP Pygoat` | app |  |
| 27 | 2026-10-24 | ECS service starts with no NAT | ECS execution role | none | steady state first deployment, 0 stopped tasks | ECR via `ecr.api` + `ecr.dkr` + S3 gateway (task SG 443 to the S3 prefix list); `logs`; `secretsmanager` + `kms:Decrypt` |  |
| 28 | 2026-10-24 | task migrates the RDS database | task, DB user from Secrets Manager | none | `Applying auth.0001_initial... OK` (all migrations) | task SG → RDS SG 5432; `rds.force_ssl` (PG16 default) with `sslmode=require` | password injected by ECS from the RDS-managed secret; never in code or state |
