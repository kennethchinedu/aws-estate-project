# Policy rollout

How I'd roll out the five Checkov policies in `policies/checkov/` to 30 teams.

The policies: every AWS provider sets an `owner` tag, RDS is encrypted, no SSH from the internet, only eu-west-2 / eu-west-1, and no public S3 buckets.

## Report-only first

Day one, nothing blocks. Checkov runs with `--soft-fail`, so failures show in the log but the build stays green. Turn it on blocking straight away and teams with old violations get red builds they didn't cause, and they'll find a way to switch the check off.

I learned this on my own repo. The first run had 6 failures and 5 of them were wrong. The owner tags were there, set in the provider's `default_tags`, but Checkov reads the `.tf` files and can't see tags Terraform adds at plan time. I moved the check onto the provider. If that had been blocking, every team would have been stopped by my mistake.

Report-only runs for four weeks. Each failure is either fixed by the team, fixed in the policy (false positive), or given an exception.

SARIF upload to Code Scanning isn't set up yet. It needs to be before rollout, because nobody reads logs on a green build.

## Exceptions

One exists today, on the us-east-1 provider. The WAF in front of CloudFront has to live in us-east-1:

```
# checkov:skip=CKV2_CUSTOM_4: Needed to deploy and attach WAF
```

The reason is fine, but there's no owner and no end date, and Checkov skips have no expiry field. For 30 teams I'd make every skip carry a ticket and an expiry, e.g. `| ticket=SEC-123 | expires=2027-04-30`, and add a small CI step (not built yet) that fails on a skip missing them or past its date. Skip lines need a security review through CODEOWNERS. No repo-wide `--skip-check`.

## When it starts blocking

One policy at a time, using `--hard-fail-on` with the IDs that have flipped. A policy flips when, for two weeks in a row, no team has open failures for it (or only ones with a valid exception) and nobody has reported a false positive against it. Teams get two weeks' notice.

Order: RDS encryption and public S3 first, owner tag last since it's the one that already misfired. If report-only starts 2026-11-02, the first flip is 2026-11-30, then one a week.

In this repo it's already blocking. A planted `storage_encrypted = false` turned the PR red, and the revert turned it green.

## What it misses

- Modules from the Terraform Registry (my VPC and IAM ones) aren't scanned without `--download-external-modules`, and the run still goes green.
- Anything only known at plan time. That needs a scan of the plan JSON.
- Anything created outside Terraform. AWS Config catches that in the account.
