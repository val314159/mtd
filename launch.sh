#!/bin/sh
set -eu

# Does the Postgres cluster exist?
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    mkdir -p "$PGDATA"
    chown -R postgres:postgres "$PGDATA"
    su postgres -c "initdb -D '$PGDATA'"
fi

# Start PostgreSQL
su postgres -c "pg_ctl -D '$PGDATA' -w -l /var/lib/postgresql/logfile -o '-c listen_addresses=$PGHOST -p $PGPORT' start"

if [ ! -f "$PGDATA/.mtd-init-complete" ]; then
    psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE USER \"$PGUSER\";"
    psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE $PGDATABASE OWNER \"$PGUSER\";"

    for sql in /docker-entrypoint-initdb.d/*.sql; do
        [ -e "$sql" ] || continue
        psql -U "$PGUSER" -d "$PGDATABASE" -v ON_ERROR_STOP=1 -f "$sql"
    done

    touch "$PGDATA/.mtd-init-complete"
fi

# Start Nginx
nginx -g 'daemon off;' &

# Start Celery beat and worker
su app -s /bin/sh -c 'celery -A mtd.celery_app beat --loglevel=info --schedule=/tmp/celerybeat-schedule' &
su app -s /bin/sh -c 'celery -A mtd.celery_app worker --loglevel=info'
