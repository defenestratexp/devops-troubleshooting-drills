# Git: the key was removed four months ago

**Budget:** ~40 minutes

## The report

A secret scanner flagged `AKIAIOSFODNN7EXAMPLE` in this repository.

The engineer who owns it pushed back, with evidence: `config.py` reads its
credentials from the environment, and has done since commit 5, four months
ago. There is no key in the working tree. `grep -r` across the checkout finds
nothing.

    ./setup.sh
    cd repo
    grep -r AKIAIOSFODNN7EXAMPLE .        # nothing
    git log --oneline

The scanner is right and the engineer is right. Both things are true, and the
gap between them is the whole exercise.

Three things are required of you:

1. The key must not be recoverable from `repo/` by **any** means — not from
   history, not from a dangling object, not from the reflog.
2. The repository must still work: `repo/config.py` at HEAD still reads from
   the environment, `importer.py` and `uploader.py` are intact, and the
   history is still a history (you may rewrite it; you may not throw it away).
3. Write `ROTATION.md` in **this** directory saying what you would do about
   the key itself, and when, relative to the cleanup.

Requirement 3 is the one that matters most. Do not skip it.

Needs git. The key is AWS's published example key and has never been valid.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
