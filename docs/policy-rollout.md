# Policy rollout: Checkov custom policies

How I'd take the five policies in `policies/checkov/` from "a check in my repo" to something 30 teams actually live with, without them working around it.

## 1. What's being rolled out, and why not all at once

Five checks, all run against Terraform source in CI:

| ID | What it stops |
|---|---|
| CKV2_CUSTOM_1 | An AWS provider without a non-empty `owner` in `default_tags` |
| CKV2_CUSTOM_2 | An RDS instance without storage encryption |
| CKV2_CUSTOM_3 | A security group open to `0.0.0.0/0` on port 22 |
| CKV2_CUSTOM_4 | A provider outside eu-west-2 / eu-west-1 |
| CKV2_CUSTOM_5 | An S3 bucket without all four public-access-block switches on |

If I switched these on as blocking on day one, every team with an old violation would get a red pipeline they didn't cause and can't fix quickly. The quickest way out of that is `--skip-check` on the whole repo, and then the gate is gone. So it goes in quiet first.

## 2. Report-only first

Checkov runs on every PR with `--soft-fail`: FAILED lines show in the job log, the job stays green, nothing is blocked. That's how the gate went into this repo (PR #9).

Report-only runs for four weeks. During that time I go through each team's failures with them and sort every one into:

- **real**: they fix it
- **false positive**: I fix the policy
- **accepted exception**: it gets a skip (section 3)

Right now findings only show in the job log. SARIF upload to GitHub Code Scanning isn't set up yet. That comes before the rollout, because nobody reads CI logs on green builds.

Why this matters, from this repo: the first run against the real Terraform failed **6** checks. Five were the owner-tag policy, and all five were false positives. The tags were there, but they come from the provider's `default_tags`, and Checkov reading the `.tf` files can't see tags that Terraform only merges in at plan time. I moved the check onto the provider block. The sixth failure was a real exception (below). 6 failed → 0 after triage, without changing any infrastructure. If that policy had been blocking on day one, every team would have been stopped by my bug.

## 3. Exceptions

There's one in this repo today, on the `aws.us_east_1` provider:

```
# checkov:skip=CKV2_CUSTOM_4: Needed to deploy and attach WAF
```

It's justified: a WAF attached to CloudFront has to be created in us-east-1. But it's not good enough for 30 teams. It doesn't say who approved it or when it should be looked at again. Checkov skip comments have no expiry field, so I'd add a convention and a small CI check:

```
# checkov:skip=CKV2_CUSTOM_4: CloudFront WAF must be in us-east-1 | ticket=SEC-123 | expires=2027-04-30
```

- The CI check (not built yet) greps every `checkov:skip` and fails if `ticket=` or `expires=` is missing or the date has passed.
- Skip lines are covered by CODEOWNERS, so adding one needs a security review.
- No repo-wide `--skip-check` in pipelines. A skip is per resource, with a reason, or it doesn't go in.

## 4. Metrics

Every week, per team and per policy:

- open failures on the default branch
- skips in use, and how many are past expiry
- false positives reported against each policy

These policies have no severity levels, so I don't gate on "criticals". I gate on the counts above, per policy.

Current state of this repo: 33 passed, 0 failed, 1 skipped. When I planted `storage_encrypted = false` on the database, the gate went red on CKV2_CUSTOM_2 (32 / 1 / 1). After the revert it was green again.

## 5. Switching to enforcing

Policies flip one at a time, not all five together, so if something breaks I know which policy caused it. A policy flips when, for two weeks in a row:

1. every team has zero open failures for it on the default branch, or each one left has a skip with a ticket and an expiry, and
2. no new false positives have been reported against it.

Teams get two weeks' notice of the date, in the channel they actually read and in the PR comment.

Order: start with the ones least likely to hit legitimate setups, end with the one that hit false positives:
CKV2_CUSTOM_2 (RDS encryption) and CKV2_CUSTOM_5 (public S3) first, then _3 (SSH), _4 (regions), and _1 (owner tag) last.

Dates, if report-only starts Mon 2026-11-02: first flip no earlier than Mon 2026-11-30, the rest one per week after that if the criteria hold.

Mechanically, one policy at a time means Checkov's `--hard-fail-on CKV2_CUSTOM_2,...` (block on these IDs, report the rest), adding IDs as they flip. In this repo all five are already enforcing (`--soft-fail` removed), and a planted violation turned the PR red.

## 6. What this gate can't see

- **Registry modules.** The VPC and IAM modules come from the Terraform Registry. Without `--download-external-modules`, Checkov skips them and still reports green. That needs a decision before rollout: turn it on, or accept the gap and cover it elsewhere.
- **Values Terraform works out.** Code mode reads text. Anything only known at plan time (merged tags, computed values) needs a scan of `terraform show -json` on the plan.
- **Anything not made through Terraform.** Console clicks and scripts never pass through CI. AWS Config rules (e.g. `required-tags`, S3 public access) catch those in the account itself.

This gate is the first and cheapest layer. It isn't the only one.
