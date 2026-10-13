# Solution: Compose: published port refuses connections

> Stop. Have you run `./verify.sh`?

The process binds to 127.0.0.1 INSIDE the container's network namespace.

`ports: "8080:3000"` makes Docker forward host:8080 to the container's
interface on 3000 - but that forwarding arrives on the container's eth0, not on
its loopback. A listener bound to 127.0.0.1 is reachable only from inside that
same namespace, so the forwarded packets hit a closed port.

Fix: listen on `0.0.0.0` (or omit the host argument, which defaults to all
interfaces). In the file, change `.listen(PORT, '127.0.0.1', ...)` to
`.listen(PORT, '0.0.0.0', ...)`.

How to diagnose it rather than guess: exec into the container and look at what
is actually listening.

    docker compose exec api sh -c "netstat -ltn || ss -ltn"

You will see 127.0.0.1:3000 rather than 0.0.0.0:3000. This is one of the most
common real-world container faults and it looks identical to a firewall problem
from the outside, which is why you check the listener before the network.

Note the comment in server.js is a deliberate red herring - it describes the
bug as if it were intentional. Code comments are not evidence.

