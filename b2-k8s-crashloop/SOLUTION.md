# Solution: Kubernetes: CrashLoopBackOff after a config change

> Stop. Have you run `./verify.sh`?

The container references `AWS_REGION` from the ConfigMap, and that key does
not exist. The ConfigMap has APP_MODE and LOG_LEVEL only.

Critically, this does NOT look like a config error at first glance - the pod
status is CrashLoopBackOff, which points you at the application. The real state
is CreateContainerConfigError, and the kubelet reports it in events, not in
logs. `kubectl logs` is empty or useless here because the container never
started, which is itself the clue.

The command that tells you:

    kubectl -n practice describe pod -l app=cfgapp
    # Events: Error: couldn't find key AWS_REGION in ConfigMap practice/cfgapp-config

Fix either way:
  - add `AWS_REGION: us-west-2` to the ConfigMap data, or
  - mark the reference optional: `configMapKeyRef: {name: ..., key: AWS_REGION, optional: true}`

Which one is right depends on whether the app needs it. Saying "I would make it
optional only if the application has a sane default, otherwise failing fast is
correct" is a better answer than either fix alone.

The lesson to state: when logs are EMPTY, stop reading logs. Empty logs mean the
container did not run, so the fault is in the pod spec, the image, the mounts or
the node - and `describe` plus events is where that lives. People lose a lot of
time running `kubectl logs` repeatedly against something that never started.

