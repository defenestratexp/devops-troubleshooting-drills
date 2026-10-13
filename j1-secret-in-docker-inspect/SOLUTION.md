# Solution: Secrets: the password every developer can read

> Stop. Have you run `./verify.sh`?

## Why the obvious fix does nothing

Moving the value into `db.env` and using `env_file:` feels like the fix —
the secret is no longer written in the YAML, which is the file you were
looking at. But `env_file:` is a *source*, not a *mechanism*: compose reads
the file and passes the values to the Docker API as environment variables,
exactly as `environment:` does. The container's `Config.Env` is identical
either way.

The same is true of every variant people reach for:

| How you deliver it | Ends up in `docker inspect`? |
| --- | --- |
| `docker run -e PASS=value` | yes, and in your shell history |
| `docker run -e PASS` (inherit from the shell) | **yes** — cleaner argv, same `Config.Env` |
| compose `environment:` | yes |
| compose `env_file:` / `.env` | yes |
| `ENV` in a Dockerfile | yes, and in the image for everyone who pulls it |
| compose `secrets:` (a file) | no |

The one worth internalising is the second row. Using `-e PASS` so the value
does not appear in `ps` output is a real improvement for one threat and no
improvement at all for this one. The value still becomes part of the
container's configuration, and configuration is readable.

## Leak 1 and 2 — the container environments

    environment:
      POSTGRES_PASSWORD: "tr0ub4dor-horse-battery"   # db
      PGPASSWORD: "tr0ub4dor-horse-battery"          # app

Both become `Config.Env`. Replace the delivery mechanism with a mounted file:

    secrets:
      db_password:
        file: ./secrets/db_password.txt

    services:
      db:
        environment:
          POSTGRES_PASSWORD_FILE: /run/secrets/db_password
        secrets: [db_password]
      app:
        secrets: [db_password]

The file appears at `/run/secrets/db_password` on a tmpfs inside the
container. `docker inspect` shows that a secret named `db_password` is mounted
— a name and a path, not a value.

Note `POSTGRES_PASSWORD_FILE`. Most well-behaved images support a
`_FILE` variant of every secret-bearing variable for exactly this reason
(postgres, mysql, redis, many Bitnami images). Reaching for it is a good habit
and a good thing to notice when evaluating an image. The *path* is not a
secret, so having it in the environment is fine.

And `check.sh` reads the file rather than inheriting the value:

    PGPASSWORD=$(cat /run/secrets/db_password)
    export PGPASSWORD

## Leak 3 and 4 — the image

    ARG DB_PASSWORD
    ENV PGPASSWORD=${DB_PASSWORD}

Two separate leaks from two lines:

- **`ENV` writes into the image's config**, so the password ships with the
  image. Everyone who pulls it gets the password, and `docker image inspect`
  prints it. Deleting the container does not help; the image is in a registry
  and in backups.
- **`ARG` values are recorded in the layer history.** `docker image history
  --no-trunc` shows the build command including the argument value. This
  catches people who use `ARG` *specifically to avoid* `ENV`, believing it is
  build-time-only and therefore transient. It is build-time only and it is
  permanent.

A multi-stage build does not fix it either: the history of the stage you keep
is what ships, and anything `ARG`-ed into that stage is in it.

Fix: delete both lines. A secret should never be a build input. If a build
genuinely needs a credential — a private package registry, say — the mechanism
is BuildKit build secrets:

    RUN --mount=type=secret,id=npmrc npm ci

which mounts the value for that one `RUN` and records nothing in any layer.

## What this does and does not solve

Worth being precise about, because claiming too much is worse than the bug:

- The value is no longer in the image, the registry, the layer history, the
  container config, `docker compose config`, or CI logs that echo build args.
  That is the finding closed.
- It **is** still readable by anything that can exec into the container, and
  `export PGPASSWORD` in `check.sh` puts it in PID 1's environment, so
  `/proc/1/environ` has it. Tighter, for postgres specifically, is a
  `~/.pgpass` file at mode 0600 and no environment variable at all.
- `secrets: file:` means the plaintext sits on the host filesystem. For a
  laptop or a single host that is a reasonable trade. For anything real the
  file should come from a secret manager at deploy time — Vault, AWS Secrets
  Manager, SOPS-encrypted files, or Kubernetes Secrets fed by the External
  Secrets Operator — so the plaintext exists only in tmpfs on the node.
- **And the password is now known.** It was in an image that was pushed, so
  the only complete remediation is to rotate it. Closing the leak without
  rotating is housekeeping, not incident response. The order matters: rotate
  first, then fix the mechanism, because the fix takes longer than the
  exposure does.

## The general rule

A secret should reach a process as a **file** or from a **secret manager API
call at runtime**, never as part of a container's or image's declarative
configuration. Configuration is designed to be inspectable, copyable and
version-controlled — which are all the properties you do not want.

The question to ask of any secret-handling scheme: *who can read this, and
where does it get written down?* Environment variables are readable by
`docker inspect`, by `/proc/<pid>/environ`, by crash dumps, by anything that
logs its own environment on startup, and by any error reporter that ships
environment context with a stack trace.
