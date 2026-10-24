# aws-estate-project

A governed AWS multi-account estate built with plain Terraform on top of an AWS Control Tower landing
zone: organizational units, service control policies, organization-wide threat detection and
Control Tower controls, with every guardrail tested and its placement explained.

**Status: in progress.** The foundation, the first guardrails and detection are built and tested.
Identity Center ABAC, the remaining guardrails, the GitHub OIDC deployment chain and the private
workloads are planned (see [Status](#status)).

Region **eu-west-2** (London). **eu-west-1** (Ireland) is a governed region for DR; detection is
London-only for now ([DECISIONS.md](DECISIONS.md)).

## Status

| Area | Built and tested | Planned |
|---|---|---|
| Landing zone | Control Tower landing zone (v4.0) with Log Archive and Audit accounts, centralised CloudTrail and AWS Config logging, region deny; imported into Terraform | |
| Organization | OUs: Security, Sandbox, Infrastructure, Workloads (Prod, Nonprod), Policy-Staging, Suspended. Security (by the landing zone), Workloads, Prod and Nonprod registered | Register Sandbox, Infrastructure, Policy-Staging |
| Accounts | Log Archive, Audit, payments-prod, payments-dev managed in Terraform | More accounts (see [Constraints](#constraints)) |
| Service control policies | `deny-root` and `deny-cloudtrail-tampering` on the Root; `deny-log-deletion` on Security; reusable `modules/scp` | Deny leaving the org, deny IAM users and access keys, require IMDSv2, require tags in Prod, deny-all on Suspended (tested in Policy-Staging first) |
| Detection | GuardDuty and Security Hub (CIS AWS Foundations 3.0.0) delegated to Audit, every account a member | IAM Access Analyzer; alerts on break-glass use, root sign-in and SCP changes |
| Control Tower controls | 3 detective and 2 proactive controls on Prod and Nonprod | |
| Identity | Humans and Terraform sign in through IAM Identity Center (SSO, MFA, temporary credentials) | Groups and permission sets (admin, auditor, engineer, prod read-only), team session tags, ABAC |
| Data perimeter | | Resource control policy for S3, KMS and Secrets Manager; cross-account read through bucket and KMS key policies |
| Deployment | | GitHub Actions via OIDC: plan on pull requests, apply from `main` only, deployer role per workload account |
| Workloads | **payments-dev reference architecture** ([docs/reference-architecture.md](docs/reference-architecture.md)): PyGoat on ECS Fargate in private subnets behind an internal ALB, RDS PostgreSQL in isolated subnets (KMS, TLS, password managed and rotated in Secrets Manager), seven interface endpoints and no NAT, WAF (operator IP only, rate limit, four managed rule groups), AWS Backup with Vault Lock (governance). Test server reached only through SSM. Tests 21–28 | CloudFront (VPC origin to the internal ALB, S3 with origin access control): code written, waiting on AWS account verification for CloudFront |

## Organization

```
Root                         deny-root, deny-cloudtrail-tampering
├── management account       outside every OU; SCPs never apply to it
├── Security                 Control Tower guardrails + region deny, deny-log-deletion
│   ├── Log Archive          CloudTrail log buckets
│   └── Audit                delegated admin for GuardDuty and Security Hub; Config aggregator
├── Workloads                Control Tower guardrails + region deny (inherited by Prod and Nonprod)
│   ├── Prod                 payments-prod      5 detective/proactive controls
│   └── Nonprod              payments-dev       5 detective/proactive controls
├── Infrastructure           (empty)
├── Sandbox                  (empty)
├── Policy-Staging           (empty; new SCPs are tested here first)
└── Suspended                (empty)
```

## Layout

Plain Terraform, no wrappers. **Modules** are reusable and hold no state; **live/** is what gets
applied: one folder per account, region and stack, each a root module with its own state file.

```
modules/
  state-bucket/        versioned, encrypted, TLS-only S3 bucket for Terraform state (prevent_destroy)
  scp/                 one SCP from a JSON file, attached to a set of OUs or accounts
  private-workload/    EC2 with no public IP, IMDSv2, encrypted root, reached through SSM only
  workloads/
    vpc/               public, private and isolated tiers; S3 gateway and interface endpoints
    ecr-repository/    immutable tags, scan on push, lifecycle
    log-bucket/        private bucket for ALB and WAF logs
    postgres/          RDS PostgreSQL, KMS, master secret managed by RDS, client SGs only
    alb/               ALB, target group, listener, access logs
    fargate-service/   ECS cluster, service, task definition, execution and task roles, SG
    edge/              CloudFront (VPC origin, S3 with OAC) and WAF
    backup/            vault with Vault Lock, plan, selection
live/management/eu-west-2/
  bootstrap/           the state bucket itself
  landing-zone/        the Control Tower landing zone (imported)
  organization/        OUs, OU registration, SCPs, Control Tower controls
  accounts/            member accounts and their OU placement
  cicd/                GitHub OIDC provider and the plan/apply roles
  detection/           GuardDuty and Security Hub, delegated to Audit
live/payments-dev/eu-west-2/
  network/             the VPC, the data bucket, the test server
  app/                 PyGoat: ECR, RDS, ECS, ALB, WAF, CloudFront, backups (reads network's outputs)
policies/scps/         hand-written SCP JSON, read by modules/scp
docs/                  reference-architecture.md: requirements, decisions, cost, build layers
```

CI on every pull request (`.github/workflows/terraform-checks.yml`): `terraform fmt`, `validate` for
every stack, and a Trivy IaC scan that fails on HIGH or CRITICAL. Accepted findings are listed with
their reasons in `.trivyignore.yaml`.

Each stack keeps its state in S3 at `<account>/<region>/<stack>/terraform.tfstate`, encrypted, with
native S3 locking (`use_lockfile`).

## Apply order

Run each stack from its own folder. Every stack plans **No changes** against the live estate.

| # | Stack | Notes |
|---|---|---|
| 1 | `bootstrap` | First apply with local state; then add `backend.tf` and run `terraform init -migrate-state` to move the state into the bucket it created. |
| 2 | `landing-zone` | The landing zone was created in the console and imported. The manifest's `governedRegions` must keep AWS's stored order. |
| 3 | `organization` | OUs, OU registration (`aws_controltower_baseline`), SCPs and Control Tower controls. Enabling controls is a Control Tower operation and can take several minutes each; re-run on `ConflictException`. |
| 4 | `accounts` | Needs `terraform.tfvars` with the account emails (copy `terraform.tfvars.example`; the real file is gitignored). Reads OU IDs from the organization stack's state. |
| 5 | `detection` | Uses a second provider that assumes `AWSControlTowerExecution` in Audit. The management account's GuardDuty and Security Hub memberships may need a second apply (eventual consistency). |

### Prerequisites

- Terraform >= 1.10 (for S3 native state locking); AWS provider `~> 6.0`.
- An IAM Identity Center profile with admin access to the management account, for example:
  ```bash
  aws configure sso          # profile name: mgmt-admin
  aws sso login --profile mgmt-admin
  export AWS_PROFILE=mgmt-admin
  ```

## Constraints

- **Five accounts.** The organization's account quota was not raised, so payments-prod and payments-dev
  were enrolled rather than vended through Account Factory, and the analytics and sandbox accounts do
  not exist. payments-dev stands in for the consumer side of cross-account tests.
- **Existing organization.** The estate runs in an existing AWS organization alongside other workloads;
  teardown removes this estate's resources only.
- **One pre-existing IAM user** with an access key remains in the management account for another
  system. It is documented as an exception in [DECISIONS.md](DECISIONS.md).

## Evidence

- [DECISIONS.md](DECISIONS.md): where each guardrail is enforced and why, plus the other design decisions.
- [TEST-LOG.md](TEST-LOG.md): for every test, the prediction, the actual result and the deciding policy.
