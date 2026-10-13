# Solution: Kubernetes: pod flaps Ready then NotReady under load

> Stop. Have you run `./verify.sh`?

`timeoutSeconds` defaults to **1 second**, and it is almost never written down
in a manifest. The handler takes 1.6s, so every probe times out, readiness never
holds, and the liveness probe eventually kills the container - producing a
restart loop with no application errors anywhere.

This is a documented trap in my own environment: 35 probes in the n9n-k8s
repo still carry the default.

Fix - set the timeout to something realistic, and give slow starts a startup
probe rather than a generous liveness probe:

    readinessProbe:
      httpGet: {path: /healthz, port: 8080}
      periodSeconds: 5
      timeoutSeconds: 3
    livenessProbe:
      httpGet: {path: /healthz, port: 8080}
      periodSeconds: 10
      timeoutSeconds: 3
    startupProbe:
      httpGet: {path: /healthz, port: 8080}
      periodSeconds: 5
      failureThreshold: 12     # 60s to become ready, then liveness takes over

Points that land well in an interview:
- A liveness probe that can fail for a reason OTHER than the process being dead
  is a self-inflicted outage. Liveness should answer "is this process wedged",
  not "is my database up" - otherwise a database blip restarts every pod you
  have and turns a degradation into an outage.
- Readiness should include dependencies. Liveness should not. That distinction
  is the actual content of the question.
- A startupProbe exists precisely so you do not have to loosen liveness to
  accommodate slow boots.
- The comment calling the sleep "a real dependency check, not a bug" is bait.
  The sleep is not the fault; the 1-second default is.

