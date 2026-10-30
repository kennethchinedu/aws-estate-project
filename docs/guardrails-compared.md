# AWS Config vs Azure Policy

The same two rules in both clouds: no public storage, and every resource has an `owner` tag. AWS side: `live/payments-dev/eu-west-2/guardrails`. Azure side: `azure-secure-baseline/live/dev/uksouth/policy`.

## What happened when I broke each rule

| | AWS Config | Azure Policy |
|---|---|---|
| Public storage | Bucket got created. Flagged NON_COMPLIANT about 2 minutes later. Auto-remediation (SSM) turns public access block back on. | `deny`: the create request was rejected (`RequestDisallowedByPolicy`). Nothing was created. |
| Missing owner tag | Created, then flagged NON_COMPLIANT. Not auto-fixed, because a script can't know who the owner is. | Built-in is hard-coded to deny, so I assigned it with `DoNotEnforce`: created, then shown as Non-compliant. |

## The differences that matter

- **Blocking.** Azure Policy runs inside Resource Manager, so every create or update goes through it and `deny` stops the request. Config only sees a resource after it exists. To block in AWS, you need an SCP or RCP.
- **Exposure window.** AWS: a few minutes between creation, detection and remediation. Azure deny: none.
- **Fixing.** Config needs a remediation document, an IAM role (trust limited to SSM in this account) and retries. In Azure, `modify` / `deployIfNotExists` do the same job with a managed identity.
- **Report-only.** Azure has a switch on the assignment (`DoNotEnforce`). Config only ever reports, so there's nothing to switch.
- **Exceptions.** Azure has exemptions with an expiry date. Config has nothing built in: you'd narrow the rule's scope or accept the finding.
- **Who owns the plumbing.** In AWS, Control Tower owns the Config recorder and delivery channel; I only add rules. Azure Policy has no recorder to set up.
- **Nothing to check.** Both say so explicitly: Config shows INSUFFICIENT_DATA with no resources, and Azure compliance shows nothing to evaluate. Neither result means compliant.

## Where each fits

CI (Checkov) catches it in the PR. Cloud-side rules catch what never went through CI (console clicks, scripts) and drift. In AWS that takes two tools: SCPs to block, Config to detect and fix. In Azure, Policy does both.
