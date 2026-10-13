# Solution: Terraform: plan wants to destroy and recreate everything

> Stop. Have you run `./verify.sh`?

`count` addresses resources by INDEX: `local_file.service_config[0..3]`.
Removing "beta" (index 1) shifts gamma from 2 to 1 and delta from 3 to 2, so
Terraform sees index 1 changing from beta to gamma, index 2 from gamma to delta,
and index 3 disappearing. Three resources change instead of one.

For real resources whose name is immutable - IAM roles, S3 buckets, RDS
instances - that is a destroy and recreate of live infrastructure.

Fix: address by a stable KEY instead of position.

    resource "local_file" "service_config" {
      for_each = toset(var.services)
      filename = "${path.module}/out/${each.value}.conf"
      content  = "service=${each.value}\n"
    }

Addresses become `local_file.service_config["beta"]`, and removing beta affects
exactly that one.

This is a top-tier interview answer because it is about BLAST RADIUS, which
Ivo's description asks for in as many words: "you think in failure modes... when
this breaks, what happens next". Things to add:
- Migrating an existing `count` resource to `for_each` is not free. You either
  accept the churn or move state: `terraform state mv 'x[1]' 'x["beta"]'` for
  each element. Knowing that migration has a cost is part of the answer.
- `terraform plan` output is the artifact you read before apply. "I read the plan
  and I count destroys" is a concrete habit, not a platitude.
- Guardrails that catch this in CI: require a plan artifact on the PR, fail the
  pipeline on unexpected destroys, and use `prevent_destroy` lifecycle blocks on
  anything whose loss is unrecoverable.

