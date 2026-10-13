Baseline, then break it, then observe:

    terraform init
    terraform apply -auto-approve
    terraform state list          # note the addresses

Now remove "beta" from the default list in variables.tf and:

    terraform plan

Count how many resources Terraform wants to change. Then fix the code so the
same edit touches only one.
