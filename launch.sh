#!/bin/sh
# Start PostgreSQL
su postgres -c 'pg_ctl -D /var/lib/postgresql/data -w -l /var/lib/postgresql/data/postmaster.pid -o "-p 5432" start' &&
# Start Nginx
nginx -g 'daemon off;' &
# Start Celery worker with PostgreSQL backend
celery -A your_app worker --loglevel=info --broker=postgresql://$POSTGRES_USER:$POSTGRES_PXASSWORD@$POSTGRES_DB@localhost/$POSTGRES_DB
