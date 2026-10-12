# aws-estate-project

Governed AWS multi-account estate for a UK fintech: Control Tower landing zone, OUs, SCPs, RCP data
perimeter, IAM Identity Center with ABAC, GitHub OIDC deployment chain, private workloads via SSM,
break-glass and detection. Region **eu-west-2** (DR **eu-west-1**).

## Layout
| Folder | Contents |
|---|---|
| `bootstrap/` | Terraform state bucket (local state, applied once) |
| `landing-zone/` | Control Tower landing zone |
| `organization/` | OUs, `scps/`, `rcps/` |
| `identity/` | IAM Identity Center groups, permission sets, ABAC |
| `accounts/` | Account vending (manual Account Factory first, AFT later) |
| `workloads/` | Private EC2, SSM, VPC endpoints, Parameter Store |
| `detection/` | Break-glass alerts, Access Analyzer |
| `docs/` | Supporting notes |

## Apply order
_To be written as each stack is built._

## Deliverables
- [ ] Terraform + this README (apply order)
- [ ] [TEST-LOG.md](TEST-LOG.md): prediction, actual result, deciding policy for every test
- [ ] [DECISIONS.md](DECISIONS.md): where each guardrail is enforced and why
