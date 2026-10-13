# Solution: Terraform: the tidy-up that wants to delete production

> Stop. Have you run `./verify.sh`?

## What is actually wrong

Nothing, in the usual sense. The code is correct and the plan is correct.

Terraform tracks a resource by its **address** and by nothing else. Before the
refactor the three files were at:

    local_file.config["alpha"]
    local_file.config["beta"]
    local_file.config["gamma"]

After moving the resource into a module they are at:

    module.service.local_file.config["alpha"]
    ...

Terraform sees three addresses in state that the configuration no longer
mentions — delete those — and three addresses in the configuration that are not
in state — create those. It has no way to know these are the same objects. The
`local_file` arguments being byte-identical is irrelevant; Terraform never
compares resources to each other, only an address in state to the same address
in config.

For a `local_file` the apply would be invisible. For the RDS instance, KMS key
and S3 bucket this is reduced from, it is a destroyed database, a key that can
no longer decrypt last year's backups, and a bucket name nobody else can
reclaim for a while.

## The fix

Declare the move in code, with a `moved` block (Terraform 1.1+):

    moved {
      from = local_file.config
      to   = module.service.local_file.config
    }

One block covers every instance of a `for_each` resource — you do not need one
per key. Put it at the top level, in `main.tf` or its own `moved.tf`. The plan
then lists each object as `has moved to` and the summary line becomes
`Plan: 0 to add, 0 to change, 0 to destroy.`

Note that `terraform plan -detailed-exitcode` still exits 2 at this point, and
that is correct — the move has not been recorded yet, so applying it *will*
change the state file. The apply performs only the move, touches nothing real,
and after it the plan is genuinely empty. If you gate CI on a clean plan, this
is the one case where "exit 2" is the expected answer for exactly one run.

## Why not `terraform state mv`

    terraform state mv 'local_file.config["alpha"]' 'module.service.local_file.config["alpha"]'

This works, and before 1.1 it was the only option. It is the wrong answer here
for reasons worth saying out loud in an interview:

- It is a one-off side effect on one copy of the state. Your colleague pulling
  the branch still gets the destroy plan. So does CI. So does every other
  environment this module was extracted for in the first place.
- It is not in the diff, so no reviewer can see that a state surgery is part of
  this change.
- It is imperative and not idempotent — run it twice and the second one errors.

A `moved` block travels with the code, applies in every workspace, is visible
in review, and is a no-op once every state has caught up. You can delete the
blocks a release later, after everything has applied.

## The habit this is really teaching

**Any plan containing a destroy you did not ask for is a full stop**, and the
first question is always "did an address change?" — a `count` to `for_each`
switch, a rename, a move into or out of a module, a re-keyed `for_each`, a
resource that grew a `for_each` it did not have. All of them are address
changes and all of them are fixed with `moved` rather than with courage at the
confirmation prompt.

The companion habit is never piping a plan straight into an apply in CI without
a gate on destroys. `terraform plan -out` then a check on
`terraform show -json` for `"actions": ["delete"]` catches the whole class.
