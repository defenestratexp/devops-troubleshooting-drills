# S3: cross-account read denied, and the bucket policy allows it

**Budget:** ~40 minutes

## The report

Account B's `PartnerReader` role gets `AccessDenied` on every object in
`n9n-data-exchange`, which lives in account A.

The bucket policy names that exact role ARN and allows `s3:GetObject`. The
role's own identity policy allows `s3:GetObject`. Both policies have been
read out loud on a call twice.

    $ aws s3 cp s3://n9n-data-exchange/feeds/2026-10-12/orders.csv .
    fatal error: An error occurred (AccessDenied) when calling the GetObject
    operation: Access Denied

    $ aws s3 ls s3://n9n-data-exchange/feeds/2026-10-12/
    2026-10-12 04:15:22      18244 orders.csv
    2026-10-12 04:15:31       2011 returns.csv

Listing works. Reading does not.

Everything known about the bucket is in `bucket-facts.md`; the three policies
are in `policies/`. There are **three** independent reasons this call fails,
and fixing any one of them alone changes nothing.

This one is graded on your reasoning rather than by running anything: write
`ANSWERS.md`, then `./verify.sh`.

No AWS account needed.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
