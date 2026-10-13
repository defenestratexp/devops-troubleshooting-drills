# Solution: Compose: wrong password despite the env file

> Stop. Have you run `./verify.sh`?

`environment:` beats `env_file:`.

Compose precedence, lowest to highest:
  1. Dockerfile ENV
  2. `env_file:` entries
  3. `environment:` entries in the service
  4. a value from the shell when you write `environment: [FOO]` with no `=`
  5. `docker compose run -e`

So `PGPASSWORD: changeme` in the api service silently overrides the
`PGPASSWORD=s3cret-from-file` that the same service loads from db.env.

Fix: delete the `environment:` block from the api service (or correct the value
there, but deleting is the honest fix since the file is meant to be the source).

Two more things worth knowing, because interviewers probe them:
- `.env` is NOT the same mechanism. It supplies variables for INTERPOLATION in
  the compose file itself (`${FOO}`), and is not automatically injected into
  containers. The `.env` here is a decoy.
- The reliable way to settle any argument about which value won:

      docker compose run --rm api env | grep PGPASSWORD
      docker compose exec api env | grep PGPASSWORD   # for a running one

  Check the environment the PROCESS actually has, never the file you think it
  read. That habit generalises far beyond compose.

