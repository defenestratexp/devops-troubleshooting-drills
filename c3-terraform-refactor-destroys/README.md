# Terraform: the tidy-up that wants to delete production

**Budget:** ~30 minutes

## The report

We moved three resources into a reusable module. No resource arguments changed
— same names, same content, same filenames. The diff is pure code movement.

The plan wants to destroy all three and create three new ones.

These are config files in the drill. In the change this is reduced from they
were an RDS instance, a KMS key and an S3 bucket, and the engineer noticed at
the confirmation prompt.

Your job: make the refactored code apply to the existing state with **no
destroys, no replacements and no creates** — a completely empty plan.

The fix has to work for a colleague who has never run this, and in CI. "Run
this command once on your laptop first" does not count.

No cloud credentials needed; this uses the `local` provider.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
