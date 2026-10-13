# IAM: the deploy role that can read the customer data bucket

**Budget:** ~45 minutes

## The report

An access review flagged the CI deploy role. The policies attached to it are in
`policies/`. The ten requests the role must and must not be able to make are in
`requests.json`, each with the reason it is there.

Three of the ten come out wrong today. Fix the policies.

    ./verify.sh

`iam_eval.py` is the grader, and it is also the thing worth reading: it is the
IAM evaluation algorithm in about forty lines. You are allowed to read it. You
are not allowed to edit it, or `requests.json` — those are the requirements.

One fix will make things briefly worse, in a way that teaches you something.
Keep going when it does.

Needs only python3. No AWS account and no credentials — nothing here talks to
AWS.

## What the evaluator does and does not implement

It covers: explicit `Deny` beats everything, otherwise an `Allow` from any
statement wins, otherwise the default is deny; `Action`/`NotAction` and
`Resource`/`NotResource`; and IAM's `*` and `?` wildcards.

It does not cover conditions, resource-based policies, permission boundaries,
SCPs, or session policies. The policies here do not use them.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
