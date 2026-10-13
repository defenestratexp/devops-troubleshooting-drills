# VPC: the private subnet that cannot reach anything

**Budget:** ~45 minutes

## The report

A new environment was built from a modified copy of an older one. Three things
are wrong with it:

1. Instances in the private subnet cannot reach the internet at all, so
   package installs and S3 calls time out.
2. The load balancer gets connection timeouts to the application port. The app
   is running and listening.
3. The security review flagged that SSH is reachable from the internet.

`network.json` is the environment: subnets, route tables, NACLs, security
groups. `flows.json` is what must and must not work, each with the reason.

    ./verify.sh

There are **five** defects behind those three symptoms. Two of the five only
appear once you have fixed something else, so expect the output to change shape
as you go rather than simply shrink.

`net_eval.py` is the grader. Read it — it is the packet walk, in order, and it
names the layer that dropped each flow. Do not edit it, or `flows.json`.

Needs only python3. No AWS account and no credentials.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
