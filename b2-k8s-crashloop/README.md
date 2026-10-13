# Kubernetes: CrashLoopBackOff after a config change

**Budget:** ~30 minutes

## The report

A deploy went out and the pod is now in CrashLoopBackOff. The previous
version was fine. The team says "nothing changed in the image".

    kubectl apply -f manifest.yaml
    kubectl -n practice get pods -l app=cfgapp

Get the pod Running and staying up. Say what the failure actually was before
you fix it.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
