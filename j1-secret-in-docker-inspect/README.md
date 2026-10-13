# Secrets: the password every developer can read

**Budget:** ~35 minutes

## The report

An incident review found the production database password in three places
nobody had thought of:

    docker inspect <container> | grep -i password
    docker image history j1-app:drill
    docker compose config

Anyone in the `docker` group can run all three — and being in the `docker`
group is already root-equivalent, so that part is not the finding. The finding
is that the password is now in the image, which is in a registry, which is
backed up, and in every CI log that printed the build arguments.

This drill is the same shape, with a fake password.

    docker compose up -d --build
    docker compose logs app          # AUTHENTICATED
    docker inspect $(docker compose ps -q app) | grep -c tr0ub4dor

Make it so that:

1. The app still authenticates to the database — `AUTHENTICATED` in its logs.
2. The password does not appear in `docker inspect` for **either** container.
3. The password does not appear in the image: not in `docker image history`,
   not in the image's own config.

There is an obvious fix that does not work. Finding out why it does not work is
most of the value here, so try it before you read the solution.

Needs Docker and Docker Compose. The password is fake.

## Rules

- No AI assistance while solving. That is the point of the drill.
- Man pages, `--help` and official docs are fair game.
- Narrate out loud as if someone is watching, because in the real interview someone is.
- Run `./verify.sh` to grade yourself. Open `SOLUTION.md` only after it passes, or after you have genuinely stalled for 15 minutes.
