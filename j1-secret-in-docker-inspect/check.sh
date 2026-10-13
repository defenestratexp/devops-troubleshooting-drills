#!/bin/sh
# Authenticates to the database and reports. psql reads PGPASSWORD from the
# environment.
until psql -h db -U postgres -tAc 'select 1' >/dev/null 2>&1; do
  sleep 1
done
echo AUTHENTICATED
sleep infinity
