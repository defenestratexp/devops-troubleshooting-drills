What is deployed today is in `baseline/` — that is the code that produced the
current state. The refactored version is the top level: a thin root calling
`./modules/service`.

Reproduce it by hand to see the plan for yourself:

    rm -rf .work && mkdir .work && cp baseline/*.tf .work/
    cd .work && terraform init && terraform apply -auto-approve
    terraform state list                      # note these addresses exactly

    rm *.tf && cp ../*.tf . && cp -r ../modules .
    terraform init
    terraform plan                            # three destroys, three creates

Now compare the two `state list` outputs — the one you noted and the addresses
the new plan is proposing to create. Terraform identifies a resource by its
address and by nothing else. Ask what changed about the addresses, and what
tells Terraform that the thing at the old address and the thing at the new
address are the same object.

Then make the plan empty. Only edit files at the top level or under
`modules/` — `baseline/` is a record of what is already deployed, so changing
it is rewriting history rather than fixing the problem.
