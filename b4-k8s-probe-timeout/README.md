# Kubernetes: pod flaps Ready then NotReady under load

**Budget:** ~35 minutes

## The report

A service restarts itself every couple of minutes in production. Readiness
flaps. The application logs show no errors and the endpoint it serves is
genuinely fine when you curl it by hand - just not instant.

    kubectl apply -f manifest.yaml
    kubectl -n practice get pods -l app=slowstart -w

Make it stable and Ready without removing the probes - they are there for a
reason. This is a real gotcha from my own notes.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
