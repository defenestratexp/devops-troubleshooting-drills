First, find all three leaks yourself:

    docker compose up -d --build

    # the container's configuration
    docker inspect $(docker compose ps -q app) | grep -i tr0ub4dor
    docker inspect $(docker compose ps -q db)  | grep -i tr0ub4dor

    # the image's build history, layer by layer
    docker image history --no-trunc j1-app:drill | grep -i tr0ub4dor

    # and the image's own baked-in environment
    docker image inspect j1-app:drill --format '{{json .Config.Env}}'

Then **try the obvious fix**: move the value out of `compose.yaml` into a
`.env` file or an `env_file:`, so it is no longer written in the YAML. Rebuild
and re-run the `docker inspect` commands.

It is still there. Work out why: what does `env_file:` actually do with those
values, and at what point does the thing you are trying to hide become part of
the container's configuration? The lesson is that the leak is not about where
you *typed* the secret — it is about the mechanism you used to deliver it.

So the questions:

  1. Which delivery mechanisms put a value into the container's `Config.Env`,
     and therefore into `docker inspect`? (`-e`, `--env-file`, compose
     `environment:`, compose `env_file:` — which of those are different in the
     end state, and which are only different in where you typed it?)
  2. `ARG` followed by `ENV` in a Dockerfile — which of those ends up in the
     image's layer history, which in the image's config, and does a multi-stage
     build change the answer?
  3. What mechanism delivers a secret to a running container *without* it
     becoming part of the container's configuration? Look up compose
     `secrets:`, and what the postgres image does with `POSTGRES_PASSWORD_FILE`
     rather than `POSTGRES_PASSWORD`.

You will need to change `compose.yaml`, the `Dockerfile` and `check.sh`.
