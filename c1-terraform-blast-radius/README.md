# Terraform: plan wants to destroy and recreate everything

**Budget:** ~30 minutes

## The report

Someone removed one item from the middle of a list variable. The plan now
shows destroy-and-recreate on resources that should not have been touched. In
production this would have deleted live objects.

    terraform init && terraform apply -auto-approve    # establish the baseline
    # then edit variables.tf: remove "beta" from the list
    terraform plan

Your job: make removing a middle element affect ONLY that element. Nothing else
in the plan should be destroyed or replaced. No cloud credentials needed - this
uses the local provider.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
