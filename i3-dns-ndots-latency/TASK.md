Look at what the resolver actually does:

    docker compose up -d
    docker compose exec dns sh -c ': > /var/log/dns/queries.log'
    docker compose exec client getent ahosts api.vendor.test
    docker compose exec dns cat /var/log/dns/queries.log

You will see several questions for one lookup. The second field is the query
type — 1 is A, 28 is AAAA.

Now read the resolver configuration the client was given:

    docker compose exec client cat /etc/resolv.conf

Three things are set there, and all three are the defaults a Kubernetes pod
gets. The questions:

  1. What does `search` do to a name the application asked for?
  2. What does `ndots` decide? Specifically: `ndots:5` with the name
     `api.vendor.test` — count the dots, compare with 5, and say what the
     resolver does first as a result.
  3. In what order are the candidates tried, and when does it stop?

Then predict, before changing anything, how many questions each of these would
produce under the current configuration:

    api.vendor.test                 (2 dots)
    api.vendor.test.                (trailing dot -- what does that mean?)
    payments                        (0 dots)
    a.b.c.d.e.vendor.test           (6 dots)

Check your predictions with the log. Then fix it, keeping requirement 2 in
mind — the fix is a change to how the client resolves names, not to the
application and not to the DNS server.

`man resolv.conf` has all of it, under `search` and `options ndots`.
