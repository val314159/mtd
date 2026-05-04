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

RUN sed -i 's/listen 80 default_server;/listen 8080 default_server;/' /etc/nginx/http.d/default.conf \
    && sed -i 's/listen \\[::\\]:80 default_server;/listen [::]:8080 default_server;/' /etc/nginx/http.d/default.conf

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

RUN echo 'alias ll="ls -la"' >/root/.profile

# Set PostgreSQL environment variables
ARG POSTGRES_USER=myuser
ARG POSTGRES_DB=mydatabase

#ENV POSTGRES_USER=$POSTGRES_USER
#ENV POSTGRES_DB=$POSTGRES_DB
ENV PGDATA=/var/lib/postgresql/data
ENV PGHOST=127.0.0.1
ENV PGPORT=5432
ENV PGUSER=$POSTGRES_USER
ENV PGDATABASE=$POSTGRES_DB

# Configure PostgreSQL (minimal setup)
RUN mkdir -p /var/run/postgresql /var/lib/postgresql/data \
    && chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql/data \
    && su postgres -c "initdb -D /var/lib/postgresql/data"

# Copy application code and configuration files
COPY  . /app
WORKDIR /app

RUN mkdir -p /docker-entrypoint-initdb.d/
RUN cp sql/* /docker-entrypoint-initdb.d/

# Start services using tini
ENTRYPOINT ["/sbin/tini"]
CMD ["/app/launch.sh"]

# Expose ports
EXPOSE 8080 443 5432
