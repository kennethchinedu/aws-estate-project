# aws-estate-project

Governed AWS multi-account estate for a UK fintech: Control Tower landing zone, OUs, SCPs, RCP data
perimeter, IAM Identity Center with ABAC, GitHub OIDC deployment chain, private workloads via SSM,
break-glass and detection. Region **eu-west-2** (DR **eu-west-1**).

## Layout
Plain Terraform. **Modules** are reusable and hold no state; **live/** is what gets applied —
one folder per account → region → stack, each a root module with its own state file.

```
modules/                      reusable Terraform modules (variables.tf / main.tf / outputs.tf; no backend, no provider)
  state-bucket/  scp/  permission-set/  private-workload/  cross-account-role/
live/
  <account>/<region>/<stack>/ root module: versions.tf, backend.tf, providers.tf, main.tf (calls modules)
policies/                     hand-written JSON: scps/ rcps/ boundaries/ trust/
```

| Account | Stacks |
|---|---|
| `management` | bootstrap (state bucket, local state, applied once), landing-zone, organization (OUs, SCPs, RCP), identity, accounts, detection |
| `payments-prod`, `payments-dev`, `analytics-prod`, `sandbox` | workloads |

Each stack's state lives at `s3://aws-estate-tfstate-763054201886/<account>/<region>/<stack>/terraform.tfstate`.

## Apply order
_To be written as each stack is built._

## Deliverables
- [ ] Terraform + this README (apply order)
- [ ] [TEST-LOG.md](TEST-LOG.md): prediction, actual result, deciding policy for every test
- [ ] [DECISIONS.md](DECISIONS.md): where each guardrail is enforced and why
