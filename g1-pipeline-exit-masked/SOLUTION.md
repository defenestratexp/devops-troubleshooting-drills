# Solution: CI: the pipeline is green and the tests are failing

> Stop. Have you run `./verify.sh`?

`set -e` is at the top of the script, and all three defects are cases where
`set -e` does not do what people assume. That is the lesson: `set -e` is not
"abort on any failure". It is a narrow rule with a long list of exemptions, and
every one of these three is on that list.

## Defect 1 — a pipeline reports the status of its LAST command

    ./run-tests.sh unit | tee build/unit.log

The exit status of a pipeline is the status of the **rightmost** command. `tee`
succeeds at writing the log, so the pipeline's status is 0, and `set -e` sees
nothing to abort on. The failures are printed, captured, and ignored.

Fix:

    set -o pipefail

With `pipefail`, the pipeline returns the rightmost **non-zero** status, so the
test failure survives the `tee`. Keep the `tee` — logging the output is a
requirement, and the usual "fix" of dropping it just trades one defect for a
lost log.

The same trap, in the wild: `curl … | bash`, `mysql < dump.sql | tee`,
`terraform plan | grep -v Refreshing`, and anything piped into `jq`. Every one
of those silently discards the left-hand status without `pipefail`.

## Defect 2 — `set -e` is suspended for conditions

    if run_integration_tests; then
      log "integration suite passed"
    else
      log "integration suite reported a problem"
    fi

When a command's failure is being *tested* — in `if`, `while`, `until`, or on
the left of `&&`/`||` — `set -e` is deliberately disabled for it. It has to be,
or `if` could never test a failing command. So the failure is caught by the
`else` branch, logged, and then the script carries on, because logging is not
the same as failing.

Fix: handle it, then actually fail.

    else
      log "integration suite FAILED -- see build/integration.log"
      exit 1
    fi

The `else` branch that logs and falls through is the single most common way a
pipeline lies. It reads as error handling, which is why it survives review.

## Defect 3 — `|| something` is an exemption too

    ./deploy.sh || log "deploy reported warnings (non-fatal)"

Same mechanism as defect 2 in a shorter form. `deploy.sh` failing is handled by
the `||`, so the compound command succeeds, and the script continues to
`log "pipeline complete"`.

Fix:

    ./deploy.sh || { log "deploy FAILED"; exit 1; }

Note the braces: `|| log … ; exit 1` would exit 1 on *every* run, including
successful ones, which the grader also catches.

## The corrected header

    set -euo pipefail

- `-e` abort on an unhandled failure
- `-u` abort on an unset variable, which catches the empty-expansion family of
  bugs (`rm -rf "$PREFIX/"` with `PREFIX` unset)
- `-o pipefail` do not let a pipeline hide a failure

This is the line to be able to write from memory and to justify in three
sentences.

## What `set -e` still will not catch

Worth knowing, because `set -euo pipefail` is not a guarantee:

- A failure inside a command substitution: `x=$(false)` assigns and continues
  in some contexts.
- A failing command in a function called from a condition — the exemption
  propagates into the whole function body.
- The script's own exit status, if the last command is something like `log`.
  A pipeline whose final line is an `echo` exits 0 no matter what came before,
  which is why an explicit `exit 0` at the end is actively harmful.
- Background jobs. `set -e` never sees them; you need `wait` and its status.

## The habit

The real failure here was not a shell bug, it was **trusting a green tick that
nobody had ever seen go red**. A pipeline whose failure path has never been
exercised is not a pipeline, it is decoration.

Cheap and worth doing: a deliberately failing commit on a branch, once, to
watch the tick go red. Better: a test in the pipeline's own repository that
runs the pipeline against a known-bad fixture and asserts a non-zero exit —
exactly what `verify.sh` does here.
