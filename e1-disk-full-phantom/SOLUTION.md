# Solution: Linux: disk is full but nothing is using the space

> Stop. Have you run `./verify.sh`?

A file's blocks are freed when the last reference goes away. `rm` removes the
DIRECTORY ENTRY, but a process holding an open file descriptor is still a
reference, so the space stays allocated. `du` walks the directory tree and
cannot see a file with no name; `df` reads the filesystem's own accounting and
can. That gap between df and du IS the diagnosis.

The ten-second command:

    sudo lsof +L1 /tmp/practice-disk
    # or:  sudo lsof -nP /tmp/practice-disk | grep deleted

`+L1` lists files whose link count is below 1 - deleted but still open. It will
name the process and the fd.

Fixes, best first:
  1. Signal the process to reopen its logs - for a real daemon that is a HUP, or
     `systemctl reload`. Correct, no data loss, no downtime.
  2. Truncate through the still-open fd without killing anything:
         sudo truncate -s 0 /proc/<pid>/fd/9
     Frees the blocks immediately while the process keeps writing. This is the
     move that impresses people, because it solves it with zero disruption.
  3. Kill the holder. Works, loses whatever it was doing.
  4. Reboot. What the team suggested, and never necessary for this.

Why this is a good interview story: it is a case where the obvious tool lies to
you. `du` is not wrong, it is answering a different question. Saying "df and du
disagreeing is itself a signal, and it means deleted-but-open or a mount
shadowing a populated directory" shows a mental model rather than a memorised
command.

The OTHER cause of df/du disagreement, worth naming: something is mounted over a
directory that already had files in it. Those files still occupy space and are
invisible while the mount is active.

