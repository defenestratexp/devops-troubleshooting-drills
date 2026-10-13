# Linux: disk is full but nothing is using the space

**Budget:** ~30 minutes

## The report

Alert: filesystem 98% full on a log host. You delete the obvious large log
file and `df` does not budge. `du -sh` on the mount adds up to far less than
`df` reports. The team wants to reboot. Talk them out of it, and reclaim the
space without one.

    ./setup.sh        # creates the situation in a loopback filesystem

Reclaim the space and make verify.sh pass. Requires sudo for the loop mount.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
