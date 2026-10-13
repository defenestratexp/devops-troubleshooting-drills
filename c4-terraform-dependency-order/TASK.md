Prove it to yourself on a clean tree:

    rm -rf out .terraform terraform.tfstate*
    terraform init
    terraform apply -auto-approve

Read the error and note *which* object Terraform was working on, and at which
phase of the run it gave up. Then ask the question that cracks it:

    In what order does Terraform do these three things --
      evaluate a data source,
      build the dependency graph,
      run a resource's provisioner?

There is a reference in the config from the manifest to the data source, and a
reference from the data source to a filename. Draw the graph Terraform builds
from those references, and then draw the graph you actually need. The missing
edge is the bug.

Pass condition: `terraform apply` succeeds on the **first** run from a clean
tree, `out/manifest.json` carries the same version string as
`out/version.txt`, and a second apply changes nothing.
