FROM alpine:latest

RUN apk add --no-cache \
    tini nginx \
    python3 py3-pip \
    postgresql postgresql-contrib postgresql-client
    
RUN pip install --break-system-packages \
    celery psycopg2-binary kombu sqlalchemy

RUN echo 'alias ll="ls -la"' >/root/.profile

RUN adduser -D -h /app app

ARG NGINX_HTTP_PORT=8080
ARG NGINX_HTTPS_PORT=1443
ARG POSTGRES_PORT=5432

ARG POSTGRES_USER=myuser
ARG POSTGRES_DB=mydatabase

ENV PGDATA=/var/lib/postgresql/data
ENV PGHOST=127.0.0.1
ENV PGPORT=$POSTGRES_PORT
ENV PGUSER=$POSTGRES_USER
ENV PGDATABASE=$POSTGRES_DB
ENV PYTHONPATH=/app/src

ARG NGINX_CONF=/etc/nginx/http.d/default.conf
RUN sed -i -E "s/listen[[:space:]]+80([[:space:];])/listen ${NGINX_HTTP_PORT}\1/g" $NGINX_CONF \
 && sed -i -E "s/listen[[:space:]]+\\[::\\]:80([[:space:];])/listen [::]:${NGINX_HTTP_PORT}\1/g" $NGINX_CONF \
 && sed -i -E "s/listen[[:space:]]+443([[:space:]]+ssl[[:space:];])/listen ${NGINX_HTTPS_PORT}\1/g" $NGINX_CONF \
 && sed -i -E "s/listen[[:space:]]+\\[::\\]:443([[:space:]]+ssl[[:space:];])/listen [::]:${NGINX_HTTPS_PORT}\1/g" $NGINX_CONF

RUN mkdir -p             /run/nginx /var/lib/nginx /var/log/nginx \
 && chown -R nginx:nginx /run/nginx /var/lib/nginx /var/log/nginx

# Configure PostgreSQL (minimal setup)
RUN mkdir -p /var/run/postgresql /var/lib/postgresql/data \
 && chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql/data

# Copy application code and configuration files
COPY  src /app/src
COPY  sql /app/sql
WORKDIR /app
RUN chown -R app:app /app

RUN mkdir -p /docker-entrypoint-initdb.d/
RUN cp sql/* /docker-entrypoint-initdb.d/

RUN touch    /usr/local/bin/mtd-launch \
 && chmod +x /usr/local/bin/mtd-launch \
 && cat    > /usr/local/bin/mtd-launch <<'SH'
#!/bin/sh
set -eu
if [ ! -s "$PGDATA/PG_VERSION" ]; then
        mkdir -p "$PGDATA"
        chown -R postgres:postgres "$PGDATA"
        su postgres -c "initdb -D '$PGDATA'"
fi
su postgres -c "pg_ctl -D '$PGDATA' -w -l /var/lib/postgresql/logfile -o '-c listen_addresses=$PGHOST -p $PGPORT' start"
if [ ! -f "$PGDATA/.mtd-init-complete" ]; then
        psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE USER \"$PGUSER\";"
        psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$PGDATABASE\" OWNER \"$PGUSER\";"
        touch "$PGDATA/.mtd-init-complete"
fi
nginx -g 'daemon off;' &
su app -s /bin/sh -c 'celery -A mtd.celery_app beat --loglevel=info --schedule=/tmp/celerybeat-schedule' &
su app -s /bin/sh -c 'celery -A mtd.celery_app worker --loglevel=info'
SH

# Start services using tini
ENTRYPOINT ["/sbin/tini"]
CMD ["/usr/local/bin/mtd-launch"]

# Expose ports
EXPOSE $NGINX_HTTP_PORT $NGINX_HTTPS_PORT $POSTGRES_PORT
