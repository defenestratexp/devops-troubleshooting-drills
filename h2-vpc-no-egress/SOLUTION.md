# Solution: VPC: the private subnet that cannot reach anything

> Stop. Have you run `./verify.sh`?

Five defects, three symptoms. Taken in the order the grader surfaces them.

## Defect 1 — the private route table has no default route

    "private": [ { "dest": "10.0.0.0/16", "target": "local" } ]

Only the VPC-local route. Nothing matches `203.0.113.10`, so the packet is
dropped before any security layer is consulted — which is why this looks like
a total blackout rather than a filtered port.

    { "dest": "0.0.0.0/0", "target": "nat-0f9e8d" }

**Why not the internet gateway?** An IGW performs one-to-one NAT between an
instance's private address and its *own public address*. An instance in a
subnet with no public IP has no public address to translate to, so the IGW has
nothing to do and the packet dies. That is the whole reason NAT gateways exist:
a NAT gateway has its own public address and does many-to-one translation on
behalf of instances that have none.

The two conditions for "public subnet" are worth stating together, because
either one alone is useless: a default route to an IGW **and** a public IP on
the instance. The grader enforces both.

Also note the NAT gateway itself must sit in a **public** subnet — it needs the
IGW route. A NAT gateway in the private subnet it serves is a loop, and a
genuinely common mistake.

## Defect 2 — the private NACL has no inbound ephemeral rule

Fix the route and the flow fails further along:

    dropped by nacl 'private' ingress: no rule allows 203.0.113.10 port 49152 (the reply)

This is the defect worth the most in an interview. The private NACL allows
outbound 443, so the request leaves. The reply comes back **from** port 443
**to** the ephemeral port the kernel chose — 49152 here — and a network ACL is
**stateless**, so that reply is a brand new packet that must match an inbound
rule on its own merits. The only inbound rule is `8080 from 10.0.0.0/16`, so
the reply is dropped by the implicit deny at the end of the list.

    { "rule": 110, "action": "allow", "protocol": "tcp",
      "ports": "1024-65535", "cidr": "0.0.0.0/0" }

The symptom this produces in real life is the memorable part: the connection
does not get refused, it **hangs** and then times out, because the SYN left and
the SYN-ACK was silently discarded. "Outbound works, replies never arrive" is
the NACL signature.

A security group would not need this. Security groups are **stateful** — an
allowed outbound connection's return traffic is admitted automatically, which
is why the `app` SG has no inbound rule for the reply and does not need one.
That asymmetry is the single most important fact about the two mechanisms.

## Defect 3 — the private NACL has no outbound ephemeral rule either

The same mistake in the other direction, and it only appears once defect 4 is
fixed:

    dropped by nacl 'private' egress: no rule allows 10.0.1.10 port 49152 (the reply)

When the load balancer calls the app on 8080, the app's **reply** is outbound
traffic from the private subnet to the load balancer's ephemeral port. The
private NACL's egress list only has 443 and 80.

    { "rule": 120, "action": "allow", "protocol": "tcp",
      "ports": "1024-65535", "cidr": "10.0.0.0/16" }

Scoped to the VPC rather than `0.0.0.0/0`, since these replies only ever go to
callers inside it. Which is the general rule for a stateless firewall: **every
allowed flow needs two rules**, one per direction, and the return rule is on
the ephemeral port.

This is why most real VPCs leave NACLs at the default allow-all and do all
filtering in security groups. Hardening a NACL is easy to get wrong in exactly
this way, and the failure mode is a hang rather than an error. Use NACLs for
coarse, direction-wide guardrails — block a hostile CIDR, deny a subnet from
talking to the internet at all — not for per-service rules.

## Defect 4 — the app security group admits the wrong source

    { "protocol": "tcp", "ports": "8080", "source": "10.0.99.0/24" }

`10.0.99.0/24` is not a subnet in this VPC. The load balancer is at
`10.0.1.10`, so nothing matches, and the security group's implicit deny drops
it — another hang, not a refusal.

The fix is not to write the load balancer's CIDR. It is to reference its
security group:

    { "protocol": "tcp", "ports": "8080", "source_sg": "alb" }

A security group referencing another security group means "whatever is in that
group, wherever it is, however many there are". Replace the load balancer,
scale it, move it to another subnet, renumber the VPC — the rule keeps working.
A CIDR-based rule has to be maintained by hand every time the topology moves,
and the pressure is always to widen it to the whole VPC to make the problem go
away, which is how flat internal networks happen.

## Defect 5 — SSH open to the world

    { "protocol": "tcp", "ports": "22", "source": "0.0.0.0/0" }

Delete it. There is no version of this that is correct on an internet-facing
load balancer.

Note which layer caught it: the public subnet's NACL is the AWS default, which
allows everything, so the security group is the only control. That is normal
and fine — but it means an over-permissive SG rule in a public subnet is
directly exposed, with nothing behind it.

What to say instead of "restrict it to the office IP": SSH access to instances
should go through SSM Session Manager, which needs **no inbound rule at all**
(the agent dials out), no bastion, no key distribution, and logs every session.
If a bastion is genuinely required, it gets its own tiny security group, and
instance SGs reference that group rather than any CIDR.

## The debugging order worth memorising

When something in a VPC cannot reach something else, the layers in order:

1. **Route table** — is there a route, and is its target capable of what you
   are asking? (IGW needs a public IP; NAT needs a public subnet.)
2. **Security group egress** on the source.
3. **NACL egress** on the source subnet.
4. **NACL ingress** on the destination subnet.
5. **Security group ingress** on the destination.
6. **The return path**, for NACLs only, on the ephemeral port — both subnets.
7. Only then the host: is it listening, and on which interface?

And the one diagnostic that short-circuits most of it: **VPC Flow Logs**, where
`REJECT` tells you a security layer dropped it and the absence of any record at
all tells you it was routing. In the console, Reachability Analyzer does this
whole walk for you and names the blocking component — the same job as
`net_eval.py` here.

The tell that separates layers without any tooling: a **connection refused** is
a host with nothing listening; a **timeout** is a packet being dropped
silently, which means a security group, a NACL or routing.
