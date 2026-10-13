# Kubernetes: Service returns no route to host

**Budget:** ~30 minutes

## The report

An alert fires: the web service is returning errors through its Service. The
Deployment shows 2/2 pods Ready. Curling the Service from inside the cluster
times out.

    kubectl apply -f manifest.yaml
    kubectl -n practice run probe --image=curlimages/curl:8.11.1 --rm -it \
      --restart=Never -- curl -s --max-time 5 http://web/

Make that curl return HTML. Requires a cluster - run ../setup-k3d.sh first.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
