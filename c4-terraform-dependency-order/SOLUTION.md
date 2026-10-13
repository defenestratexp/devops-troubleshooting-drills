# Solution: Terraform: works for everyone who has already run it

> Stop. Have you run `./verify.sh`?

## The error

    Error: Read local file data source error
      with data.local_file.version,
      Original Error: open ./out/version.txt: no such file or directory

Terraform is reading the data source before the provisioner that creates the
file has run. That is not a bug in Terraform — it is the documented order of
operations, and it is the thing worth being able to explain:

1. Terraform builds the dependency graph from **references in the
   configuration**.
2. Data sources whose arguments are all known are read **during plan**.
3. Resources — and therefore their provisioners — run **during apply**.

So the data source is read in step 2 and the file appears in step 3. On a
machine that has run this before, `out/version.txt` is left over from last
time, the read succeeds against stale content, and nobody notices. That is why
it only breaks on a clean checkout, and why "it works on my machine" was
literally true.

## Why the graph has no edge

The manifest references the data source, and the data source references a
string. Nothing in the configuration references `terraform_data.build`. A
filename is just text — Terraform cannot tell that some other resource happens
to write to that path. Dependencies come from references, never from meaning.

The graph Terraform built:

    terraform_data.build        (an island)
    data.local_file.version  ->  local_file.manifest

The graph you need:

    terraform_data.build  ->  data.local_file.version  ->  local_file.manifest

## The fix

    data "local_file" "version" {
      filename   = "${path.root}/out/version.txt"
      depends_on = [terraform_data.build]
    }

`depends_on` on a **data source** does two things, and the second is the one
people miss: it adds the graph edge, *and* it forces the read to be deferred to
apply time. Terraform cannot know the result during plan, so anything derived
from it shows as `(known after apply)` — which is exactly right here, because
the digest genuinely is not knowable until the build step has run.

The better fix, where the producer can give you the value directly, is to
reference it and skip the filesystem round trip entirely:

    resource "local_file" "manifest" {
      content = jsonencode({ release = terraform_data.build.output })
    }

A real reference needs no `depends_on` and no deferral. Reach for
`depends_on` only when the producer genuinely cannot hand you the value —
which is most often a provisioner, a `null_resource` wrapping a CLI, or a
resource whose side effect is outside its own attributes.

## Where this bites in real infrastructure

The same shape, with worse consequences:

- `data "aws_eks_cluster_auth"` read during plan, before the cluster in the
  same configuration exists. Classic chicken-and-egg; the usual answer is to
  split the cluster and its workloads into separate applies rather than to
  paper over it.
- An `aws_iam_policy_document` data source referencing a bucket ARN built by
  string interpolation (`"arn:aws:s3:::${var.name}"`) instead of
  `aws_s3_bucket.this.arn`. Works, and creates the policy before the bucket.
- `data "aws_ami"` filtered on a name a Packer build in the same pipeline is
  about to produce.

Two habits fall out of this:

- **Reference, do not reconstruct.** Every hand-built ARN, name or path is an
  edge deleted from the dependency graph. Interpolating a string that another
  resource already exposes as an attribute is the single most common way to
  lose ordering in Terraform.
- **Test the clean-tree apply.** `rm -rf .terraform terraform.tfstate* out`
  before an apply in CI, at least on a schedule. Any config that has only ever
  been applied incrementally has untested ordering, and the first person to
  find out is whoever builds the next environment.
