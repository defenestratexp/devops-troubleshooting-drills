Work top down and WRITE DOWN each step in ANSWERS.md:

 1. Is it the network, the proxy, the app, or the database? How did you decide?
 2. What did you measure at each layer, with the exact command?
 3. What did you RULE OUT, and what evidence ruled it out?
 4. What is the actual cause?
 5. Fix it. p50 under 300ms.
 6. What would you add so this is visible next time without anyone guessing?

Useful moves:
    docker compose logs api
    docker compose exec nginx sh -c "time wget -qO- http://api:3000/"
    docker compose exec api sh -c "time nc -z db 5432"
    curl -w '@-' -s -o /dev/null http://localhost:8081/ <<'F'
      dns=%{time_namelookup} connect=%{time_connect} start=%{time_starttransfer} total=%{time_total}
    F

Cleanup:  docker compose down -v
