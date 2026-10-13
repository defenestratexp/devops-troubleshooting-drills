Establish the baseline and watch it fail to settle:

    terraform init
    terraform apply -auto-approve
    terraform plan -detailed-exitcode ; echo "exit=$?"    # 0 = clean, 2 = changes

Read that plan carefully. One of the two resources reports a kind of change you
might not expect — note the verb, it is the whole clue.

Then ask, for each resource separately:

  1. What is the input to this diff, and is that input the same on every
     evaluation?
  2. Who else writes to this file after Terraform has written it, and what does
     the provider do when it reads back something it did not write?

The fix is clean when `terraform plan -detailed-exitcode` exits 0 twice in a
row, with the `[node]` address still present and the build stamp stable across
applies.
