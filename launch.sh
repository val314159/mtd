#!/bin/sh
set -eu

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
#nginx -g 'daemon off; listen 8080;'
su nginx -s /bin/sh -c "nginx -g 'daemon off;'" &

# Start Celery worker with PostgreSQL backend
DB_URL="postgresql+psycopg2://$PGUSER@$PGHOST:$PGPORT/$PGDATABASE"
celery -A your_app \
    --broker="sqla+$DB_URL" \
    --result-backend="db+$DB_URL" \
    worker --loglevel=info
