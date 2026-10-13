# DevOps troubleshooting drills

Deliberately broken infrastructure, with a grader.

Each directory is one fault: a `README.md` that describes the symptom the way a
colleague would report it, the broken artifact itself, a `verify.sh` that decides
whether the fix actually worked, and a `SOLUTION.md` to read afterwards.

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
| `c*` | Terraform — blast radius |
| `d*` | Observability — PromQL and alert rules |
| `e*` | Systems — phantom disk usage, connection exhaustion, layered latency |
| `f*` | Applications and data — silent constraints, contract mismatches, off-by-range, swallowed writes, NULL semantics |

## Requirements

Docker and Docker Compose for the `a*` and `f*` sets, a Kubernetes cluster you
can break for `b*` (k3s or kind is plenty), Terraform for `c*`. Each exercise
says what it needs.

Passwords in these files are deliberately fake and are part of the puzzles.
