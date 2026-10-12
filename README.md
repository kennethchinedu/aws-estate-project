# aws-estate-project

Governed AWS multi-account estate for a UK fintech: Control Tower landing zone, OUs, SCPs, RCP data
perimeter, IAM Identity Center with ABAC, GitHub OIDC deployment chain, private workloads via SSM,
break-glass and detection. Region **eu-west-2** (DR **eu-west-1**).

## Layout
Terragrunt + Terraform. **Modules** are reusable and hold no state; **live/** is what gets applied —
one folder per account → region → stack, each with its own state file.

```
root.hcl                      Terragrunt root: remote state (S3, locking) + provider generation
modules/                      reusable Terraform modules (inputs/outputs, no backend/provider)
  scp/  permission-set/  private-workload/  cross-account-role/
live/
  <account>/account.hcl       account ID + the role Terragrunt assumes into it
    <region>/region.hcl       region
      <stack>/terragrunt.hcl  calls a module (or local code) with inputs
policies/                     hand-written JSON: scps/ rcps/ boundaries/ trust/
```

| Account | Stacks |
|---|---|
| `management` | landing-zone, organization (OUs, SCPs, RCP), identity, accounts, detection |
| `payments-prod`, `payments-dev`, `analytics-prod`, `sandbox` | workloads |

## Apply order
_To be written as each stack is built._

## Deliverables
- [ ] Terraform + this README (apply order)
- [ ] [TEST-LOG.md](TEST-LOG.md): prediction, actual result, deciding policy for every test
- [ ] [DECISIONS.md](DECISIONS.md): where each guardrail is enforced and why
