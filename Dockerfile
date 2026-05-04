FROM alpine:latest

# Install tini and required packages
RUN apk add --no-cache tini nginx postgresql-client postgresql-server python3 py3-pip python3-dev build-base libc6-compat\ngit && pip install celery psycopg2-binary kombu

# Set PostgreSQL environment variables
ENV POSTGRES_USER=myuser
ENV POSTGRES_PASSWORD=mypassword
ENV POSTGRES_DB=mydatabase

# Configure PostgreSQL (minimal setup)
RUN mkdir -p /var/lib/postgresql/data
RUN chown -R postgres:postgres /var/lib/postgresql/data
RUN initdb -D /var/lib/postgresql/data

# Copy custom configuration files if needed (nginx.conf, celeryconfig.py, etc.)
# COPY ./nginx.conf /etc/nginx/nginx.conf
# COPY ./celeryconfig.py /app/celeryconfig.py

# Copy launch.sh and make executable
COPY launch.sh /app/launch.sh
RUN chmod +x /app/launch.sh

# Start services using tini
ENTRYPOINT ["/sbin/tini"]
CMD ["/app/launch.sh"]

# Expose ports
EXPOSE 80 443 5432