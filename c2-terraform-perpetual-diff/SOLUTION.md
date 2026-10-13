# Solution: Terraform: the plan is never clean

> Stop. Have you run `./verify.sh`?

Two causes that look like one symptom. Diagnosing them together is the trap;
the plan output tells you they are different if you read the verbs.

## Cause 1 — `local_file.build_stamp`: a nondeterministic input

    content = jsonencode({ service = var.service, built_at = timestamp() })

`timestamp()` is evaluated on every plan and every apply. So `content` is
different every time, and Terraform honestly reports a change, because there
genuinely is one. The plan verb here is `~ update in-place`.

Nothing is broken in Terraform. The configuration is asking for something
impossible: "converge on a value that is different each time you look at it."

Fix: take the clock out of the desired state.

    variable "build_id" { type = string, default = "local-dev" }
    content = jsonencode({ service = var.service, build_id = var.build_id })

CI passes the real value (`TF_VAR_build_id=$GIT_SHA`), which is what you
actually wanted to record anyway — a commit is more useful in a support ticket
than a wall-clock time. If you genuinely want "the time this was first
created", that is the `time_static` resource from the `hashicorp/time`
provider: it records the timestamp once, at create, and keeps it in state.

`ignore_changes = [content]` also silences this one, and it is the wrong
answer. It does not remove the nondeterminism, it just stops you being told
about it — and it would equally suppress a real change to `var.service`.

## Cause 2 — `local_file.app_config`: two writers, one file

The plan verb on this one is `+ create`, not `~ update`. That is the clue, and
it is strange: the resource is in state and the file is on disk, so why would
Terraform create it?

Because it is **not** in state any more. The `local` provider's read for
`local_file` hashes the file and compares it to what it wrote. The provisioner
appended `[node]` after the write, so the hash no longer matches, and the
provider concludes the resource it manages no longer exists and removes it from
state. The next plan therefore proposes to create it — and the next apply
**overwrites the file, silently deleting the `[node]` section**. The perpetual
diff is not the bug. The data loss on the next apply is the bug.

This is why `ignore_changes` cannot save you here, and the reason is worth
being able to state out loud: `ignore_changes` filters the diff between
configuration and prior state. This drift was handled during *read*, before
there is any diff to filter. There is no prior state left to ignore against.

The real defect is that one file has two writers. Fix it by giving each writer
its own file:

    resource "local_file" "app_config" {
      filename = "${path.module}/out/app.conf"
      content  = "[app]\nservice=${var.service}\ninclude=conf.d/*.conf\n"
    }

    resource "terraform_data" "node_dropin" {
      input = var.service
      provisioner "local-exec" {
        command = "mkdir -p ${path.module}/out/conf.d && printf '[node]\\naddress=127.0.0.1\\n' > ${path.module}/out/conf.d/node.conf"
      }
    }

Terraform owns `app.conf` completely; the node owns its drop-in; neither reads
back something it did not write. `terraform_data` is built in, so this needs no
extra provider. A `null_resource` works the same way.

The other legitimate fix is to stop having a second writer at all — pass the
address in as a variable and let Terraform render the whole file. Prefer that
when the value is actually knowable at plan time. It usually is, and people
reach for provisioners long before they have to.

## Why this matters beyond the local provider

The shape generalises to anything where a config-management tool and a machine
both edit one artifact: an `authorized_keys` that Ansible templates and a
script appends to, a `resolv.conf` owned by both DHCP and a playbook, an
`/etc/hosts` written by cloud-init and by a role. The symptom is "it keeps
flapping back"; the cause is contested ownership; the fix is almost always
`conf.d`, not a smarter diff.

Two rules worth keeping:

- **A perpetual diff is a message, not noise.** Either an input is
  nondeterministic or something outside Terraform is editing what Terraform
  owns. Both are real problems. Suppressing the diff loses the only signal you
  had.
- **`ignore_changes` is for attributes whose truth legitimately lives
  elsewhere** — an autoscaling group's `desired_count`, a password rotated by
  another system, a write-only field the API never returns. It is not a
  silencer for a config you have not finished designing.
