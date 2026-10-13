# Solution: Kubernetes: Service returns no route to host

> Stop. Have you run `./verify.sh`?

The Service selector is `app: web-frontend`. The pods are labelled
`app: web` and `tier: frontend`. Nothing matches, so the Service has an empty
endpoint list and traffic goes nowhere.

The diagnostic that settles it in one command:

    kubectl -n practice get endpoints web

No addresses means selector-versus-label, every time. A Service is just a label
query plus a virtual IP; if the query matches nothing there is nothing to route
to, and the pods being Ready is irrelevant.

Fix: make the selector match, e.g. `selector: {app: web}`.

Why this is worth drilling: "pods are Ready but the Service is broken" is a
category where people start tcpdumping. The endpoint list is the first thing to
look at and it is free. Useful follow-ups to mention:

    kubectl -n practice get pods --show-labels
    kubectl -n practice describe svc web      # Endpoints: <none>

Related trap: a Service with no `selector` at all is legal - it means you manage
the EndpointSlice yourself, which is how people wire a Service to an external
database. So "no selector" is not automatically a bug; "selector matching
nothing" is.

