Reproduce both incidents:

    rm -rf releases current && mkdir releases
    ./deploy.sh 1.0.0 ; echo "exit=$?" ; readlink current
    ./deploy.sh 1.0.0 ; echo "exit=$?"            # Tuesday
    ./deploy.sh 1.1.0 ; echo "exit=$?" ; readlink current
    ./deploy.sh 1.2.0 ; echo "exit=$?" ; readlink current ; ./healthcheck.sh

After that last one, look at what `current` points at and what the health
check says. That is the Thursday outage, in two lines.

The questions worth answering in order:

  1. Which commands in this script fail when the thing they are creating
     already exists, and which of those have a flag that makes them a no-op
     instead?
  2. In what order does the script (a) switch traffic and (b) find out whether
     the new release works? What order do you need?
  3. When the health check fails, what does the script still know that it would
     need in order to put things back? Is it still available at that point?
     (`readlink current`, captured at the right moment.)
  4. `rm -f current` followed by `ln -s …` -- how long is the window where
     `current` does not exist, and is there a way to replace a symlink without
     ever removing it? (`man ln`, and look up what `-n` does to a symlink that
     points at a directory.)
