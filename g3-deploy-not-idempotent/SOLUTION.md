# Solution: Deploys: cannot run it twice, cannot get back

> Stop. Have you run `./verify.sh`?

Four separate properties are missing. They are worth naming individually,
because in an interview "make the deploy safe" is not an answer and these four
are.

## 1. Idempotence — `mkdir` without `-p`

    mkdir releases/"$VER"

Fails if the directory exists, so the second attempt at the same version dies
before it does anything. Every deploy mechanism gets retried: a network blip,
a pipeline re-run, a flaky agent, somebody pressing the button twice. A deploy
that cannot be retried is a deploy that needs a human every time anything
twitches.

    mkdir -p releases/"$VER"

`cp -r artifacts/"$VER"/. releases/"$VER"/` is already idempotent — it
overwrites. The general habit: every step should describe the state it wants,
not the transition it expects to make. That is the whole idea behind
declarative configuration management, and it applies just as much to a 20-line
shell script.

## 2. The switch happens before the check

    rm -f current
    ln -s releases/"$VER" current
    ./healthcheck.sh

Traffic moves to the new release, and only then does anyone ask whether it
works. For the eleven minutes of the Thursday outage, `current` pointed at a
release that could not start.

Check first, then switch. `healthcheck.sh` takes a release directory precisely
so this is possible:

    if ! ./healthcheck.sh "releases/$VER"; then
      echo "release $VER failed its health check; not switching" >&2
      exit 1
    fi

This is the shape of every safe rollout, under different names: a readiness
probe that must pass before a pod joins a Service's endpoints; a load
balancer health check that must pass before an instance is put in service; a
canary that takes 1% of traffic before the other 99%. In all of them the new
thing proves itself *before* it is given work.

## 3. No rollback — the information is thrown away

When the health check fails, the script has no idea what was running a moment
ago, because `rm -f current` destroyed the only record of it. Capture it first:

    previous=$(readlink current 2>/dev/null || true)

and use it as a backstop if the post-switch check fails anyway:

    if ! ./healthcheck.sh; then
      [ -n "$previous" ] && { ln -sfn "$previous" current.new; mv -T current.new current; }
      exit 1
    fi

Keep **both** gates. The pre-switch check stops the obvious failures; the
post-switch check catches what only shows up once the release is live, and the
rollback bounds how long that lasts. "Fail forward only" is a choice, and it is
the wrong one when the previous version is sitting right there on disk.

Note also what makes the rollback cheap here: releases are kept side by side
under `releases/` and `current` is a pointer. Rolling back is moving a pointer,
not re-running a build. Any deploy scheme where going back costs the same as
going forward will not be used under pressure.

## 4. The swap is not atomic

    rm -f current
    ln -s releases/"$VER" current

Between those two lines `current` does not exist. It is a short window, but a
request that arrives in it gets an error, and the failure is invisible after
the fact. `ln -sfn` is better but still removes and recreates.

The atomic form is a rename:

    ln -sfn "releases/$VER" current.new
    mv -T current.new current

`mv -T` (`--no-target-directory`) on an existing symlink is a `rename(2)`,
which the kernel guarantees is atomic: any observer sees either the old target
or the new one, never nothing. Without `-T`, `mv` would helpfully move the
symlink *into* the directory `current` points at, which is its own confusing
bug.

Worth knowing that this is the same primitive behind safe file writes
everywhere: write to a temp file in the same filesystem, `fsync`, then
`rename` over the target. It is how `git` updates refs and how most config
writers avoid a torn file.

## The whole fixed script

    #!/usr/bin/env bash
    set -euo pipefail

    VER="${1:?usage: deploy.sh VERSION}"
    cd "$(dirname "$0")"
    [ -d "artifacts/$VER" ] || { echo "no such artifact: $VER" >&2; exit 2; }

    previous=$(readlink current 2>/dev/null || true)

    mkdir -p releases/"$VER"
    cp -r artifacts/"$VER"/. releases/"$VER"/

    if ! ./healthcheck.sh "releases/$VER"; then
      echo "release $VER failed its health check; not switching" >&2
      exit 1
    fi

    ln -sfn "releases/$VER" current.new
    mv -T current.new current

    if ! ./healthcheck.sh; then
      echo "post-switch check failed; rolling back to ${previous:-nothing}" >&2
      if [ -n "$previous" ]; then
        ln -sfn "$previous" current.new
        mv -T current.new current
      fi
      exit 1
    fi

    echo "deployed $VER"

## What is still missing, and worth saying so

A good answer names the limits of its own fix:

- **Nothing prunes `releases/`.** It grows until the disk fills, which is its
  own 3am page. Keep the last N.
- **One health check at one instant** is a weak gate. A real one polls for a
  period, and ideally watches error rate and latency rather than just "the
  process started".
- **This deploys to one host.** Across a fleet you want them staggered, with
  the rollout stopping itself when the failure rate crosses a threshold —
  otherwise the fast, atomic, idempotent deploy breaks all the machines
  reliably and simultaneously.
- **The rollback assumes the previous release is still safe to run.** If the
  bad release migrated a database, the symlink going back does not undo that.
  That is why schema changes are deployed separately from, and backwards
  compatible with, the code that uses them.
