# GitHub Actions: review this workflow before it ships

**Budget:** ~40 minutes

## The report

This workflow is in a pull request, waiting on your review. It works — it runs
the tests and it deploys. You are the second reviewer; the first one approved
it.

There are **five** defects. One of them lets any stranger on the internet read
your production AWS credentials, and it is the one that looks most like a
helpful feature. Two are reliability defects that will bite on a busy day. Two
are supply-chain and reproducibility defects.

Fix `.github/workflows/ci.yml` in place. Keep the workflow doing its job: tests
on pull requests, tests plus a deploy on `main`, coverage still uploaded, the
deploy still gated behind the tests.

    ./verify.sh

(The workflow lives at `.github/workflows/ci.yml` *inside this exercise
directory*. GitHub only runs workflows from that path at the repository root,
so this one is inert — it is a file to review, not a live pipeline.)

Needs python3 with PyYAML.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
