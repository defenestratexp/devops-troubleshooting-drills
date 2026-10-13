#!/usr/bin/env bash
# Hunts for the password in every place a container's configuration is
# readable, and separately proves the app still authenticates with that same
# password -- so changing the password is not a way to pass.
cd "$(dirname "$0")"
command -v docker >/dev/null || { echo "SKIP - docker not installed"; exit 0; }

SECRET='tr0ub4dor-horse-battery'
finish() { docker compose down -v --rmi local >/dev/null 2>&1; }

docker compose up -d --build >/dev/null 2>&1 || {
  echo "FAIL - docker compose up --build failed:"
  docker compose up --build 2>&1 | tail -8 | sed 's/^/  /'
  exit 1
}

app=$(docker compose ps -q app)
db=$(docker compose ps -q db)
[ -n "$app" ] && [ -n "$db" ] || { echo "FAIL - the app or db container is not running"; finish; exit 1; }

ready=""
for _ in $(seq 1 40); do
  docker compose logs app 2>/dev/null | grep -q AUTHENTICATED && { ready=1; break; }
  sleep 1
done
if [ -z "$ready" ]; then
  echo "FAIL - the app never authenticated"
  docker compose logs --tail 10 app 2>&1 | sed 's/^/  /'
  finish; exit 1
fi

fails=0
note() { echo "FAIL - $1"; fails=$((fails+1)); }

# The password must still BE the password: exec -e sets it for this one command
# only, so it never becomes part of the container's configuration.
got=$(docker compose exec -T -e PGPASSWORD="$SECRET" db \
        psql -U postgres -tAc 'select 1' 2>/dev/null | tr -d '[:space:]')
[ "$got" = "1" ] || note "the database no longer accepts the original password; changing it is not the fix"

hunt() { # label, command...
  local label="$1"; shift
  if "$@" 2>/dev/null | grep -qi "$SECRET"; then
    note "the password is still visible in $label"
  fi
}

hunt "docker inspect of the app container" docker inspect "$app"
hunt "docker inspect of the db container"  docker inspect "$db"
hunt "docker compose config"               docker compose config

app_image=$(docker inspect -f '{{.Config.Image}}' "$app" 2>/dev/null)
if [ -n "$app_image" ]; then
  hunt "the app image's build history"  docker image history --no-trunc "$app_image"
  hunt "the app image's own config"     docker image inspect "$app_image"
fi

finish
[ "$fails" -eq 0 ] && { echo "PASS - the app authenticates and the password is in no container or image configuration"; exit 0; }
echo "-- $fails problem(s) remaining"
exit 1
