# What the incident timeline looked like

    02:14  the api pods begin returning 503 to every request
    02:19  the pods start failing their liveness probes and are restarted
    02:23  CrashLoopBackOff; the metrics endpoint is no longer reachable
    02:28  Prometheus marks the api series stale
    08:40  a customer email reaches support
    08:52  an engineer looks at the dashboard, sees a flat line at zero
           errors for the last six hours, and initially concludes the
           graph is broken rather than the service
    09:05  the service is rolled back and recovers

No alert fired at any point. The on-call phone was working; a test alert sent
at 09:30 arrived in four seconds.

Between 02:14 and 02:23 the error ratio was genuinely above the threshold.
