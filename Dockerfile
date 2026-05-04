# Use official Alpine image as base
FROM alpine:latest

#RUN apk add --no-cache \ 
#    --repository https://dl-cdn.alpinelinux.org/alpine/edge/main \ 
#RUN apk add --no-cache \ 
#    tini nginx postgresql-client postgresql-server python3 py3-pip \ 
#RUN apk add --no-cache \ 
#    python3-dev build-base libc6-compat

#RUN apk update && apk upgrade
#RUN apk add postgresql postgresql-contrib postgresql-client postgresql-dev

RUN apk add --no-cache \ 
    tini nginx

RUN apk add --no-cache \ 
    python3 py3-pip
#    python3-dev build-base libc6-compat python3 py3-pip

RUN apk add --no-cache \ 
    postgresql postgresql-contrib postgresql-client # postgresql-dev

#RUN apk add --no-cache \ 
#    --repository https://dl-cdn.alpinelinux.org/alpine/edge/main \ 
#    tini nginx postgresql-client postgresql-server python3 py3-pip \ 
#    python3-dev build-base libc6-compat

# Install Python dependencies
RUN pip install --break-system-packages \
    celery psycopg2-binary kombu

# Set PostgreSQL environment variables
ENV POSTGRES_USER=myuser
ENV POSTGRES_PASSWORD=mypassword
ENV POSTGRES_DB=mydatabase

#ENV PGUSER=postgres
ENV PGDATA=/var/lib/postgresql/data
ENV PGHOST=127.0.0.1
ENV PGPORT=5432

# Configure PostgreSQL (minimal setup)
RUN mkdir -p /var/run/postgresql /var/lib/postgresql/data \
    && chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql/data \
    && su postgres -c "initdb -D /var/lib/postgresql/data" \
    && su postgres -c "pg_ctl -D '$PGDATA' -w -l /tmp/postgres.log -o '-c listen_addresses=$PGHOST -p $PGPORT' start" \
    && psql -U postgres -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';" \
    && psql -U postgres -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;" \
    && su postgres -c "pg_ctl -D '$PGDATA' -m fast stop"

# Copy application code and configuration files
COPY  . /app
WORKDIR /app

RUN mkdir -p /docker-entrypoint-initdb.d/
RUN cp sql/* /docker-entrypoint-initdb.d/

RUN echo 'alias ll="ls -la"' >/root/.profile

# Start services using tini
ENTRYPOINT ["/sbin/tini"]
CMD ["/app/launch.sh"]

# Expose ports
EXPOSE 80 443 5432
