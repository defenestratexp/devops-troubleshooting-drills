# Solution: Compose: worker exits immediately with code 0

> Stop. Have you run `./verify.sh`?

`sh -c "node worker.js &"` backgrounds node, so the shell has nothing left to
do and exits 0. The container's lifetime is the lifetime of PID 1 - when the
shell exits, the container stops and takes the backgrounded child with it.

Exit code 0 is the tell. A crash would be non-zero. "Exited (0)" almost always
means "the foreground process finished", which in a long-running service means
you launched it wrong, not that it failed.

Fix: run it in the foreground.

    command: node worker.js

or if you genuinely need a shell wrapper, `exec` so node REPLACES the shell and
becomes PID 1:

    command: sh -c "exec node worker.js"

Two things interviewers like here:
- `exec` matters for signals too. Without it the shell is PID 1 and will not
  forward SIGTERM, so `docker compose stop` takes the full 10-second timeout and
  then SIGKILLs - which means no graceful shutdown and possibly lost work.
- `restart: always` on this would produce an infinite restart loop that looks
  healthy in `ps` and burns CPU forever. Naming the thing you are deliberately
  NOT doing, and why, reads as seniority.

