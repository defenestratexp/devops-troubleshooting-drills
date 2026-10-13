# Solution: Compose: connection refused between services

> Stop. Have you run `./verify.sh`?

DB_HOST is `database`, but the service is named `db`.

Compose puts each service on a user-defined bridge network where the embedded
DNS resolves SERVICE NAMES (and any `aliases`). There is no host called
`database`, so the lookup fails before any TCP connection is attempted.

The error code tells you this directly: EAI_AGAIN or ENOTFOUND is a DNS
failure, NOT a refused connection. ECONNREFUSED would mean the name resolved
and nothing was listening - a completely different fault. Reading the error
code rather than the error text is the whole lesson.

Fix: `DB_HOST: db`. Alternatively add `networks.aliases: [database]` to the db
service, which is what you would do if the hostname were baked into an
application you could not change.

Say out loud in an interview: "the name did not resolve, so this is DNS, not
connectivity - I would check the service name against what the client is
asking for before looking at ports or firewalls."

