# DevOps troubleshooting drills

Deliberately broken infrastructure, with a grader.

Each directory is one fault: a `README.md` that describes the symptom the way a
colleague would report it, the broken artifact itself, a `verify.sh` that decides
whether the fix actually worked, and a `SOLUTION.md` to read afterwards. Most
also have a `TASK.md` with the questions that get you there, and the ones that
need to build something first have a `setup.sh`.

The faults are not invented. Most are things I have hit in production or in my
own homelab, reduced to the smallest reproduction that still misleads you the
same way the original did.

## Running one

```sh
cd b2-k8s-crashloop
cat README.md
# ... work the problem ...
./verify.sh
```

`verify.sh` exits non-zero until the system genuinely behaves. It checks
behaviour, not the presence of a particular fix, so there is usually more than
one way to pass.

## The rules I set myself

- **No AI assistance while solving.** The point is to practise the diagnosis, and
  an assistant does the diagnosis for you.
- Man pages, `--help` and official documentation are fair game.
- Narrate out loud, because in an interview someone is listening.
- Open `SOLUTION.md` after `verify.sh` passes, or after genuinely stalling for
  fifteen minutes. Not before.

## What is here

| Prefix | Area |
| --- | --- |
| `a*` | Docker Compose — service DNS, bind addresses, env precedence, startup order, volume shadowing |
| `b*` | Kubernetes — missing endpoints, crashloops, unschedulable pods, probe timeouts |
| `c*` | Terraform — blast radius, perpetual diffs, module refactors, dependency order |
| `d*` | Observability — PromQL and alert rules, metric cardinality, alerting on absence |
| `e*` | Systems — phantom disk usage, connection exhaustion, layered latency |
| `f*` | Applications and data — silent constraints, contract mismatches, off-by-range, swallowed writes, NULL semantics |
| `g*` | CI/CD — exit codes a pipeline hides, a GitHub Actions review, an unsafe deploy |
| `h*` | AWS — IAM policy evaluation, VPC reachability, cross-account S3 |
| `i*` | TLS and DNS — certificate chains, the default vhost, resolver search domains |
| `j*` | Secrets — what `docker inspect` shows, what git history keeps |

A few are graded on reasoning rather than on a running system: they ask for an
`ANSWERS.md` and score it against the mechanisms that matter. Those say so in
their README. The rest break something real and `verify.sh` decides.

Three of the graders are small simulators rather than wrappers — IAM policy
evaluation, VPC reachability, and a DNS server that writes down every question
it is asked. They are meant to be read; each states what it does and does not
implement.

## Requirements

Docker and Docker Compose for the `a*`, `f*`, `i*` and `j*` sets, a Kubernetes
cluster you can break for `b*` (k3s or kind is plenty), Terraform for `c*`,
python3 for `d2`, `g2`, `h1` and `h2` (with PyYAML for `g2`), OpenSSL and curl
for `i1` and `i2`, and git for `j2`. Each exercise says what it needs, and
`verify.sh` skips rather than fails when a tool is missing.

`setup-k3d.sh` and `setup-terraform.sh` install what `b*` and `c*` need into
`~/.local/bin`. Nothing in here touches a real cluster, a cloud account, or a
system trust store.

Passwords in these files are deliberately fake and are part of the puzzles.
