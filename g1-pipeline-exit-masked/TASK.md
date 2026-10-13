Four runs tell you everything. Predict the exit code of each before you run it.

    FAIL_SUITES=unit ./pipeline.sh         ; echo "exit=$?"
    FAIL_SUITES=integration ./pipeline.sh  ; echo "exit=$?"
    FAIL_DEPLOY=1 ./pipeline.sh            ; echo "exit=$?"
    ./pipeline.sh                          ; echo "exit=$?"

After each failing run, check whether it deployed anyway:

    ls build/deployed.txt

Then work out, for each of the three failures separately, why `set -e` did not
stop the script. They are three different answers. The questions that get you
there:

  1. When a command is part of a pipeline, whose exit status becomes the
     pipeline's exit status?
  2. What does `set -e` do when a command's failure is being *tested* by the
     shell -- in an `if`, in a `&&`/`||` chain, or in a `while`?
  3. What is the exit status of a compound command whose failure you have
     already handled?

`help set` and `man bash` (the "Shell Builtin Commands" section, and
`pipefail`) have all of it.

Pass condition: any failing stage makes the pipeline exit non-zero and
**not** deploy; a clean run still exits 0, still deploys, and still writes
`build/unit.log`.
