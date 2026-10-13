# Terraform: works for everyone who has already run it

**Budget:** ~25 minutes

## The report

This config applies fine on every machine that has run it before. On a fresh
checkout — a new laptop, a clean CI runner, a new environment — the very first
apply fails, and it fails during the *plan*, before anything is created.

    rm -rf out .terraform terraform.tfstate*
    terraform init
    terraform apply -auto-approve         # fails here on a clean tree

Run it a second time and it works, which is how this survived code review and
three months of use. CI only noticed when the cache was cleared.

The `[build step]` that produces `out/version.txt` computes a digest that
Terraform cannot know in advance, so reading that file is genuinely necessary.
Hardcoding the value is not available to you.

No cloud credentials needed; this uses the `local` provider.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
