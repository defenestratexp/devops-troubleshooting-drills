# Terraform: the plan is never clean

**Budget:** ~35 minutes

## The report

Our CI has a "plan must be clean" gate on the main branch. It has not passed in
three weeks. Every plan wants to change something even when nobody has touched
the code, so people now apply with `-auto-approve` to shut it up and the gate
has been disabled.

    terraform init
    terraform apply -auto-approve
    terraform plan                 # still wants to change things. Run it again. Same.

There are two unrelated causes. Find both.

While you are in there: `out/app.conf` is supposed to end up with a `[node]`
section giving the node's own address. That part is a real requirement, not an
accident — the app will not start without it. Deleting it is not a fix.

No cloud credentials needed; this uses the `local` provider and writes only
under this directory.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
