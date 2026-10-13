# Kubernetes: pod stuck Pending, no events for minutes

**Budget:** ~25 minutes

## The report

A new workload will not schedule. It sits in Pending. The cluster has capacity
according to the team - "there is only one other thing running".

    kubectl apply -f manifest.yaml
    kubectl -n practice get pod -l app=hungry

Get it scheduled and Running. Do not add nodes.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
