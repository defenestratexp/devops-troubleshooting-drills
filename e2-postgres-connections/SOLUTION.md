# Solution: Postgres: FATAL too many clients, and who is to blame

> Stop. Have you run `./verify.sh`?

1. The inventory query:

     select pid, usename, state, now()-xact_start as tx_age,
            now()-state_change as in_state, left(query,60)
     from pg_stat_activity
     where backend_type='client backend'
     order by xact_start nulls last;

2. The problem state is **idle in transaction**. A plain `idle` connection holds
   a backend and some memory, and a pooler can reuse it. `idle in transaction`
   additionally holds a transaction OPEN, which means:
     - it pins the xmin horizon, so VACUUM cannot reclaim dead tuples anywhere
       in the database - table bloat grows while it sits there
     - it may hold row or table locks, blocking unrelated writers
     - it will never resolve on its own
   So it is not merely wasting a slot, it is actively degrading the database.

3. Long-running transactions:

     select pid, now()-xact_start as age, state, query
     from pg_stat_activity
     where xact_start is not null and now()-xact_start > interval '5 minutes'
     order by age desc;

4. Terminate only the offenders:

     select pg_terminate_backend(pid)
     from pg_stat_activity
     where state = 'idle in transaction'
       and now()-state_change > interval '10 minutes'
       and pid <> pg_backend_pid();

   `pg_cancel_backend` cancels the running query; `pg_terminate_backend` kills
   the session. For idle-in-transaction you need terminate - there is no query
   to cancel.

5. Raising max_connections is usually the WRONG first move, and this is the part
   interviewers are listening for. Each Postgres connection is a process with
   its own memory, and work_mem is allocated PER OPERATION per connection, so
   raising the ceiling raises the worst-case memory footprint superlinearly. You
   can convert "app gets errors" into "database OOMs", which is much worse.
   The right responses, in order:
     - fix the client that leaks transactions (a missing commit or rollback on an
       error path is the usual culprit)
     - set `idle_in_transaction_session_timeout` so the database defends itself
     - put a POOLER in front: PgBouncer in transaction mode, or RDS Proxy. This
       is exactly the RDS Proxy versus PgBouncer evaluation already done - 4.2s
       versus 27s+ failover recovery, PgBouncer ~2.2x throughput, RDS Proxy
       needing no DBA and inheriting AWS compliance.
     - cap the application pool so N workers cannot demand more than the
       database can serve. The 9,700-versus-3,604 arithmetic is this failure.
   Raise max_connections only after sizing memory for it deliberately.

6. Monitoring that pages BEFORE failure:
     - connection UTILISATION as a ratio, not a count:
       sum(pg_stat_activity_count) / pg_settings_max_connections > 0.8
     - oldest transaction age: max(now()-xact_start) > 5m
     - count of idle-in-transaction over a threshold
     - and critically, alert on the SATURATION TREND, not the failure. The
       failure is `FATAL: too many clients`, which the application already
       notices. By then you are late.

