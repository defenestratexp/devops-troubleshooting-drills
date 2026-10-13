# Deploys: cannot run it twice, cannot get back

**Budget:** ~35 minutes

## The report

Two incidents, one script.

**Tuesday.** A deploy job was retried after a network blip. The retry failed
with `mkdir: cannot create directory 'releases/1.1.0': File exists`, the
pipeline went red, and an engineer spent twenty minutes working out whether the
first attempt had actually landed.

**Thursday.** 1.2.0 was deployed. It does not start — bad config path. The
deploy script reported failure, correctly. The site stayed down for eleven
minutes while someone worked out how to get 1.1.0 back, because the script
only goes forwards.

    ./deploy.sh 1.0.0      # fine
    ./deploy.sh 1.0.0      # Tuesday
    ./deploy.sh 1.2.0      # Thursday

Make `deploy.sh` satisfy all four of these:

1. Deploying the same version twice succeeds both times and leaves the same
   result.
2. A release that fails its health check **never becomes `current`**.
3. After a failed deploy, `current` still points at the last release that was
   healthy, and the health check passes.
4. `current` is never missing or dangling, at any point, including mid-deploy.

`healthcheck.sh` takes an optional release directory and checks `current` when
given none, so you can ask it about a release you have not switched to yet:

    ./healthcheck.sh                  # whatever current points at
    ./healthcheck.sh releases/1.1.0   # one specific release

Do not edit `healthcheck.sh` or anything under `artifacts/` — 1.2.0 is
genuinely broken and must stay that way.

Needs only bash.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
