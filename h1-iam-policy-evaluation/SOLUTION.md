# Solution: IAM: the deploy role that can read the customer data bucket

> Stop. Have you run `./verify.sh`?

## Defect 1 — `DeployerConvenience`

    { "Effect": "Allow", "Action": "s3:*", "Resource": "arn:aws:s3:::n9n-*/*" }

`s3:*` is roughly 130 actions, including `DeleteObject`, `PutBucketPolicy` and
`PutObjectAcl`. `arn:aws:s3:::n9n-*/*` is every object in every bucket whose
name starts with `n9n-`, which is every bucket the account has. So this one
statement grants the deploy role full object access to customer data,
backups, logs and anything created next year under the same naming
convention.

It is also the statement that *looks* reasonable, which is why it survived.
The name tells you how it got there: something did not work, and the quickest
way to unblock the pipeline was to widen the policy until it did.

Delete it.

## The cascade — bucket ARNs and object ARNs are different resources

Deleting it breaks two requests that were passing:

    WRONG want Allow got Deny (implicit)  s3:GetObject arn:aws:s3:::n9n-artifacts/build/app.tar

Because the `Artifacts` statement was always wrong, and the over-broad
statement had been covering for it:

    "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
    "Resource": "arn:aws:s3:::n9n-artifacts"

`arn:aws:s3:::n9n-artifacts` is the **bucket**. `arn:aws:s3:::n9n-artifacts/*`
is the **objects in it**. They are different resources, and S3 actions are
split across them:

| Action | Resource it needs |
| --- | --- |
| `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` | `…/*` — the objects |
| `s3:ListBucket`, `s3:GetBucketLocation` | the bucket, with no `/` |

This is the single most common mistake in S3 policies, and it needs two
statements, not one:

    {
      "Sid": "ArtifactObjects",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::n9n-artifacts/*"
    },
    {
      "Sid": "ArtifactBucketListing",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::n9n-artifacts"
    }

Note what is no longer listed: `s3:DeleteObject`. With the broad statement
gone, "artifacts are immutable" is enforced by not granting the action at all —
an implicit deny, which is the cleanest kind.

## Defect 2 — `NoCustomerData` does not do what its name says

    { "Effect": "Deny", "NotAction": "s3:GetObject",
      "Resource": "arn:aws:s3:::n9n-customer-data/*" }

Read it literally: deny every action **except** `s3:GetObject` on customer
data. So it denies `PutObject` and `DeleteObject` there — and explicitly
carves out the one action an attacker actually wants. A `GetObject` on
customer data sails past this statement, because the statement does not apply
to it at all.

`NotAction` means "this statement is about every action other than these". In
a `Deny` it is an **allowlist of exceptions to the denial**, which is almost
never what the author meant. Whoever wrote this was reaching for "only allow
GetObject", which is a different statement in a different Effect.

Once `DeployerConvenience` is gone, no statement allows anything on
`n9n-customer-data`, so all three customer-data requests are implicitly
denied and this statement can be deleted outright. That is the better
outcome: a `Deny` that exists to cancel an over-broad `Allow` is a smell.
Shrink the `Allow` instead.

If you do want a belt-and-braces deny, write it without `NotAction`:

    { "Effect": "Deny", "Action": "s3:*", "Resource": [
        "arn:aws:s3:::n9n-customer-data",
        "arn:aws:s3:::n9n-customer-data/*" ] }

Both ARNs, for the reason in the table above.

## Defect 3 — `n9n/*` is not `n9n/deploy/*`

    "Resource": "arn:aws:secretsmanager:us-east-1:111122223333:secret:n9n/*"

Matches `n9n/prod/db-master`, `n9n/postgresql/admin`, `n9n/aws/root-keys` —
every secret in the account under that prefix. The deploy role needs
`n9n/deploy/*` and nothing else:

    "Resource": "arn:aws:secretsmanager:us-east-1:111122223333:secret:n9n/deploy/*"

Note the `-a1B2c3` on the end of the request's ARN. Secrets Manager appends a
random six-character suffix to every secret ARN, so a policy naming the secret
exactly —

    …:secret:n9n/deploy/ecr-token

— matches nothing, and the usual response to that confusing failure is to
widen the prefix until it works, which is exactly how `n9n/*` happens. The
right narrow form is `…:secret:n9n/deploy/ecr-token-*` for a single secret, or
the path prefix for a set.

## How to think about this in an interview

The evaluation order, which is the thing to be able to state cold:

1. **Default deny.** No statement, no access.
2. **An explicit `Deny` anywhere wins**, and nothing can override it — not an
   `Allow` in another policy, not an admin policy, not the resource policy.
3. Otherwise **any `Allow`** from any attached policy grants it.

And in a real account, layered on top: SCPs can deny what the account's own
policies allow, a permission boundary caps what an identity policy can grant,
and for cross-account access **both** the identity policy and the resource
policy must allow it. Those are the four places to look when "the policy says
Allow but it is being denied".

Two habits worth stating:

- **Grant actions, not wildcards.** `s3:*` in a policy is a to-do item. If you
  need twelve actions, list twelve actions — the list is also documentation of
  what the role actually does.
- **A `Deny` that exists to cancel an `Allow` means the `Allow` is wrong.**
  Reach for `Deny` for genuine guardrails — a region restriction, a protected
  bucket, an SCP preventing anyone from disabling CloudTrail — not to patch
  over a policy you have not finished narrowing.

Worth knowing the tools that answer this without guessing: the IAM policy
simulator, `aws iam simulate-principal-policy`, Access Analyzer for unused
permissions, and CloudTrail for what the role has actually called over the last
90 days — which is the honest starting point for narrowing any policy like
this one.
