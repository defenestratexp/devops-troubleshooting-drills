Start with the output. For each wrong flow the grader names the layer that
dropped it, which saves you the first half of the work. The second half is
knowing *why* that layer behaves as it does.

**Symptom 1 — no egress from the private subnet.**

  - Which route table does `private-a` use, and what is in it? What is missing?
  - When you add the default route, what do you point it at, and why can a
    private subnet not simply use the internet gateway? (What does an IGW
    actually do to a packet, and what does the instance need for that to work?)
  - Fix the route and run it again. It still fails, somewhere else. That second
    failure is the important one — see below.

**Symptom 2 — the load balancer times out.**

  - Read the `app` security group's ingress rule and work out which addresses
    it actually admits. Which address is the load balancer coming from?
  - What should the source of that rule be, so that it keeps working when the
    load balancer is replaced and gets a different address?

**Symptom 3 — SSH from the internet.**

  - Which layer is deciding this one? Note that the public subnet's network ACL
    is the AWS default, so it allows everything; that is normal, and it means
    the security group is the control.

**The one worth the most.** Two of the five defects are the same mistake in
opposite directions, and both are about this difference:

    security groups are STATEFUL
    network ACLs are STATELESS

Write down what that means for a reply packet. Specifically: when the app
opens a connection to `203.0.113.10:443`, what is the source port, and what
are the source and destination of the packet that comes *back*? Which rule in
`nacls.private` has to match it? Then do the same exercise for the reply the
app sends to the load balancer.

Pass condition: all five flows behave as `flows.json` requires.
