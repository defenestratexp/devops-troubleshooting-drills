# Solution: Compose: MODULE_NOT_FOUND after adding a bind mount

> Stop. Have you run `./verify.sh`?

The bind mount `./:/app` mounts the HOST directory over /app, hiding
everything the image built there - including /app/node_modules, which exists in
the image but not on the host.

This is the single most common "works in build, fails at run" container fault.
The build output is truthful; the runtime filesystem is simply not the one that
was built.

Fix - add an anonymous volume for node_modules so it is not shadowed:

    volumes:
      - ./:/app
      - /app/node_modules

A nested mount point takes precedence over the parent mount, so /app comes from
the host while /app/node_modules comes from the image.

Alternatives worth naming:
- Install to a parent directory (/node_modules) and let Node's resolution walk
  up. Cleanest, needs a Dockerfile change.
- Drop the bind mount and rebuild. Honest, but loses the live reload the mount
  was added for - which is the trade the developer actually cares about.

How to see it rather than deduce it:

    docker compose run --rm api ls /app/node_modules     # empty or missing
    docker run --rm $(docker compose config --images | head -1) ls /app/node_modules

