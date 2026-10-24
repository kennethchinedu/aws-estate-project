# Reference architecture: a containerised web app in payments-dev

Status: **built and tested except CloudFront** (2026-10-24, TEST-LOG 21–28). CloudFront is blocked until AWS
verifies the account for CloudFront; the distribution and VPC origin are behind `enable_cloudfront`. For testing
meanwhile, `public_alb_for_operator` makes the ALB internet-facing for the operator's IP only. One `apply` and one
`destroy` per session. Code: `live/payments-dev/eu-west-2/app` wiring the modules in `modules/workloads/`.

## Requirements
- Serve the app (PyGoat, a Django app) over HTTPS from a public domain name.
- No compute, database or endpoint with a public IP; the only public entry points are CloudFront and the ALB behind it.
- No internet egress from the workload: AWS APIs are reached through VPC endpoints, not a NAT gateway.
- No secret in code, environment files, task definitions or Terraform variables.
- Data encrypted at rest with a customer-managed KMS key, and in transit with TLS.
- Common web attacks and request floods filtered before they reach the origin.
- Logs kept outside the workload account; backups that an attacker in the account cannot delete.
- Terraform only, tagged `owner`, `purpose`, `chapter`; cost inside the budget alarm.

## Assumptions
- Account **payments-dev** (Nonprod OU), region **eu-west-2**. Its Control Tower controls and SCPs apply.
- The network stack (`live/payments-dev/eu-west-2/network`) is the base: VPC, private subnets,
  S3 gateway endpoint. Isolated database subnets and interface endpoints are added to it.
- Two availability zones (the ALB requires two). RDS single-AZ: dev, no availability target.
- Low traffic; nothing persists between sessions except Terraform state and logs.

## Request path
```
User → CloudFront + WAF + Shield Standard (*.cloudfront.net certificate)
         ├─ /static → S3 (private, origin access control)
         └─ /       → VPC origin → internal ALB (private subnets, no public IP)
                        → ECS Fargate tasks (private subnets, no public IP)
                            ├─ RDS PostgreSQL (isolated subnets, KMS)
                            └─ Secrets Manager, ECR, CloudWatch Logs via VPC endpoints
Logs → log-archive account            AWS Backup → vault with Vault Lock
```

## Decisions
| # | Decision | Choice | Why | Status |
|---|---|---|---|---|
| 1 | Where it lives | New stack `live/payments-dev/eu-west-2/app`, reading the network stack's outputs | Network and app change at different rates; separate state keeps an app destroy from touching the VPC | accepted |
| 2 | Database | RDS PostgreSQL. PyGoat ships with SQLite (`settings.py`) but already installs `psycopg2-binary`, so `DATABASES` must read host, name and credentials from the environment and Secrets Manager | SQLite inside a Fargate task is lost on every restart and can't be shared across tasks | accepted; app change needed |
| 3 | Backup Vault Lock mode | **Governance** mode in dev | Compliance mode can't be removed after its cooling-off period (minimum 3 days), and the vault can't be deleted until every recovery point expires, which breaks the per-session destroy. Production uses compliance mode | accepted |
| 4 | Egress | VPC endpoints (S3 gateway; interface: `ecr.api`, `ecr.dkr`, `logs`, `secretsmanager`, plus `ssm`, `ssmmessages`, `ec2messages` for the Session Manager test server and ECS Exec), NAT gateway off | Closes the internet path for exfiltration and keeps a shell inside the VPC to prove it; costs more than a NAT gateway at this size | accepted |
| 5 | CloudFront → ALB | **VPC origin** to an internal ALB, HTTP on that hop | No domain for an ALB certificate; a VPC origin also removes the public ALB and the prefix-list + secret-header workaround. Gap: no TLS between CloudFront and the ALB (inside AWS's network) | accepted |
| 6 | Log destination | ALB and WAF logs in a private bucket in payments-dev (SSE-S3, TLS-only policy, 30-day expiry) | Fewer moving parts in a Control Tower–managed account. Gap: production delivers to the Log Archive account | accepted |
| 7 | Exposure of a deliberately vulnerable app | WAF rule 0 blocks every source except the operator's IP; task role has no permissions | PyGoat has command-injection and SSRF labs: a shell or the task metadata endpoint must yield nothing | accepted |

## Cost (estimate; to be checked with the AWS Pricing Calculator)
| Item | ≈ per month |
|---|---|
| Interface endpoints (7 × 2 AZs) | $102 |
| ALB | $18 |
| RDS `db.t4g.micro`, single-AZ | $13 |
| Fargate (one small task) | $9 |
| WAF (web ACL + ~4 rules) | $9 |
| KMS key, Secrets Manager secret, CloudFront at low traffic | ~$2 |
| **Total** | **≈ $155/month, ≈ $0.21/hour while up** |

## Build layers
| Layer | Builds | Proof |
|---|---|---|
| L1 network | isolated DB subnets, interface endpoints, NAT off | a task pulls its image with no NAT |
| L2 image | ECR repository, scan on push, PyGoat image | scan findings listed |
| L3 data | KMS key, RDS, master password managed in Secrets Manager | database refuses anything but the task security group |
| L4 compute | ECS cluster, task definition, task role and execution role, logs | task reads its secret; red when the execution role loses access |
| L5 entry | ALB, security group chain ALB → task → RDS | |
| L6 edge | CloudFront, WAF, secret header, S3 with origin access control | direct request to the ALB refused; SQL injection through CloudFront → 403 |
| L7 resilience | logs to log-archive, AWS Backup with Vault Lock | backup deletion denied |

## Still to write
Trust boundaries, each service's security job, threats left open, the diagram.
