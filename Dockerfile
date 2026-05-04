# Use official Alpine image as base
FROM alpine:latest

# Install tini and required packages
##RUN apk add --no-cache \ 
#    --repository https://dl-cdn.alpinelinux.org/alpine/edge/main \ 
#    tini nginx postgresql-client postgresql-server python3 py3-pip \ 
#    python3-dev build-base libc6-compat

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
ENV POSTGRES_PXASSWORD=mypassword
ENV POSTGRES_DB=mydatabase

# Configure PostgreSQL (minimal setup)
RUN mkdir -p                   /var/lib/postgresql/data
RUN chown -R postgres:postgres /var/lib/postgresql/data
RUN su postgres -c "initdb -D  /var/lib/postgresql/data"
# Copy launch.sh and make executable
#COPY launch.sh /app/launch.sh
#RUN chmod +x /app/launch.sh

# Copy application code and configuration files
COPY  . /app
WORKDIR /app

# Start services using tini
ENTRYPOINT ["/sbin/tini"]
CMD ["/app/launch.sh"]

# Expose ports
EXPOSE 80 443 5432