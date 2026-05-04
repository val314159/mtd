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
    tini nginx \
    python3 py3-pip \
    postgresql postgresql-contrib postgresql-client
    
#RUN apk add --no-cache \
#    python3 py3-pip
#    python3-dev build-base libc6-compat python3 py3-pip
#RUN apk add --no-cache \
#    postgresql postgresql-contrib postgresql-client # postgresql-dev
#RUN apk add --no-cache \
#    --repository https://dl-cdn.alpinelinux.org/alpine/edge/main \
#    tini nginx postgresql-client postgresql-server python3 py3-pip \
#    python3-dev build-base libc6-compat

# Install Python dependencies
RUN pip install --break-system-packages \
    celery psycopg2-binary kombu sqlalchemy

RUN echo 'alias ll="ls -la"' >/root/.profile

RUN adduser -D -h /app app

ARG NGINX_HTTP_PORT=8080
ARG NGINX_HTTPS_PORT=1443
ARG POSTGRES_PORT=5432

# Set PostgreSQL environment variables
ARG POSTGRES_USER=myuser
ARG POSTGRES_DB=mydatabase

#ENV POSTGRES_USER=$POSTGRES_USER
#ENV POSTGRES_DB=$POSTGRES_DB
ENV PGDATA=/var/lib/postgresql/data
ENV PGHOST=127.0.0.1
ENV PGPORT=$POSTGRES_PORT
ENV PGUSER=$POSTGRES_USER
ENV PGDATABASE=$POSTGRES_DB

RUN sed -i -E "s/listen[[:space:]]+80([[:space:];])/listen ${NGINX_HTTP_PORT}\1/g" /etc/nginx/http.d/default.conf \
    && sed -i -E "s/listen[[:space:]]+\\[::\\]:80([[:space:];])/listen [::]:${NGINX_HTTP_PORT}\1/g" /etc/nginx/http.d/default.conf \
    && sed -i -E "s/listen[[:space:]]+443([[:space:]]+ssl[[:space:];])/listen ${NGINX_HTTPS_PORT}\1/g" /etc/nginx/http.d/default.conf \
    && sed -i -E "s/listen[[:space:]]+\\[::\\]:443([[:space:]]+ssl[[:space:];])/listen [::]:${NGINX_HTTPS_PORT}\1/g" /etc/nginx/http.d/default.conf

RUN mkdir -p /run/nginx /var/lib/nginx /var/log/nginx \
    && chown -R nginx:nginx /run/nginx /var/lib/nginx /var/log/nginx

# Configure PostgreSQL (minimal setup)
RUN mkdir -p /var/run/postgresql /var/lib/postgresql/data \
    && chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql/data

# Copy application code and configuration files
COPY  . /app
WORKDIR /app
RUN chown -R app:app /app

RUN mkdir -p /docker-entrypoint-initdb.d/
RUN cp sql/* /docker-entrypoint-initdb.d/

# Start services using tini
ENTRYPOINT ["/sbin/tini"]
CMD ["/app/launch.sh"]

# Expose ports
EXPOSE $NGINX_HTTP_PORT $NGINX_HTTPS_PORT $POSTGRES_PORT
