#!/bin/sh
set -eu

# Start PostgreSQL
su postgres -c "pg_ctl -D '$PGDATA' -w -l /var/lib/postgresql/logfile -o '-c listen_addresses=* -p 5432' start"

if [ ! -f "$PGDATA/.mtd-init-complete" ]; then
    for sql in /docker-entrypoint-initdb.d/*.sql; do
        [ -e "$sql" ] || continue
        psql -U postgres -f "$sql"
    done
    touch "$PGDATA/.mtd-init-complete"
fi

# Start Nginx
nginx -g 'daemon off;'
#nginx -g 'daemon off;' &
# Start Celery worker with PostgreSQL backend
#celery -A your_app worker --loglevel=info --broker=postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost/$POSTGRES_DB
