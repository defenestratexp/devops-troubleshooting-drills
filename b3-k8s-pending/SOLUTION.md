# Solution: Kubernetes: pod stuck Pending, no events for minutes

> Stop. Have you run `./verify.sh`?

The pod REQUESTS 64 CPUs and 256Gi of memory. No node can satisfy that, so the
scheduler cannot place it and it stays Pending.

    kubectl -n practice describe pod -l app=hungry
    # 0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory.

Fix: set requests to something the node has, e.g. `cpu: 100m`, `memory: 64Mi`.

The interview-relevant distinctions:
- REQUESTS drive scheduling. LIMITS drive throttling and OOMKills. A pod stuck
  Pending is always about requests (or affinity, taints, or volume topology) and
  never about limits.
- `kubectl top` shows USAGE, not requests. A cluster can be 10% utilised and
  still unschedulable because requests are reserved whether or not they are
  used. This is the single most common capacity misunderstanding, and it is
  exactly the conversation behind over-requested workloads costing money.
- The other Pending causes worth listing out loud: node selectors or affinity
  that match nothing, taints without matching tolerations, an unbound PVC, and
  topology constraints. Naming the full set shows you have a checklist rather
  than a guess.

