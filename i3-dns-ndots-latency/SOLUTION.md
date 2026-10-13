# Solution: DNS: every external call does three lookups

> Stop. Have you run `./verify.sh`?

## What the log shows

    api.vendor.test.svc.drill.local. 1
    api.vendor.test.drill.local.     1
    api.vendor.test.                 1

Three questions to resolve one name, two of them guaranteed to be NXDOMAIN,
and the real answer tried **last**.

## The mechanism

From `/etc/resolv.conf`:

    nameserver 172.31.77.10
    search svc.drill.local drill.local
    options ndots:5

`ndots` is the threshold that decides whether a name is treated as already
complete:

- A name with **fewer dots than `ndots`** is assumed to be relative, so the
  resolver appends each `search` domain in turn and tries those **first**,
  falling back to the name as given only when all of them fail.
- A name with **at least `ndots`** dots is tried as given first.
- A name with a **trailing dot** is absolute; the search list is never
  consulted. `api.vendor.test.` costs exactly one query under any
  configuration.

`api.vendor.test` has 2 dots. 2 < 5, so it is treated as relative, and the two
search domains are tried before the name the application actually asked for.

Multiply by two address families — glibc looks up A and AAAA — and one
`getent` becomes six questions on the wire. Each failed candidate is a full
round trip to the DNS server, which is where the latency came from: not DNS
being slow, but DNS being asked three times as often as necessary.

## Why `ndots:5` is there at all

It is not arbitrary, and this is the part worth being able to explain.
Kubernetes sets `ndots:5` so that **short in-cluster names work**:

    payments                                 0 dots
    payments.default                         1 dot
    payments.default.svc                     2 dots
    payments.default.svc.cluster.local       4 dots

For all of those to resolve via the search list, the threshold has to be above
4. So `ndots:5` buys convenient service discovery inside the cluster and pays
for it with three wasted queries on every external name — because almost every
external name (`api.vendor.test`, `s3.amazonaws.com`, `github.com`) has fewer
than five dots.

## The fix

    options ndots:1

In compose terms, `dns_opt: ["ndots:1"]`; in a Kubernetes pod spec:

    dnsConfig:
      options:
        - name: ndots
          value: "1"

Now `api.vendor.test` (2 dots ≥ 1) is tried as given, hits on the first query,
and the search list is never reached. And `payments` (0 dots < 1) is still
below the threshold, so it still goes through the search list and still
resolves. Both requirements, satisfied by one number.

**Why not just delete the search domains?** That is the trap the grader
catches. It fixes the external lookups and breaks every short internal name —
`payments`, and in a real cluster every service called by its bare name. The
search list is not the problem; *when it is consulted* is the problem.

The other correct fix, if you own the calling code, is to **use fully
qualified names with a trailing dot**:

    https://api.vendor.test./v1/orders

Absolute, so the search list is skipped regardless of `ndots`. It is the most
precise fix and the least popular one, because the trailing dot looks like a
typo to everyone who reads it afterwards and some libraries and TLS
implementations mishandle it.

## Worth knowing

- **This is the single most common DNS problem in Kubernetes**, and it does not
  show up as a DNS alert. It shows up as latency, as CoreDNS CPU, and as
  `conntrack` pressure on nodes — UDP flows from every pod, three times over.
  CoreDNS autoscaling is often the response, when the fix is a resolver option.
- **musl is different.** Alpine's libc does not implement the search list and
  `ndots` the way glibc does, so a service behaves differently on
  `alpine` and on `debian-slim` for reasons that have nothing to do with the
  application. This drill uses a glibc image deliberately.
- **NXDOMAIN caching matters.** Those failing lookups are cacheable; a
  negative cache (CoreDNS's `cache` plugin, or `nscd`/`systemd-resolved` on a
  host) turns three round trips into one plus two cache hits. That is
  mitigation, not a fix — but if you cannot change the resolver config, it is
  the lever you have.
- The general shape to recognise: **a sensible default for the common case,
  silently taxing the other case.** The question to ask of any resolver,
  retry policy or timeout you inherit is "what is this tuned for, and is that
  what I am doing?"
