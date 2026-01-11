FROM mysql:8.0

LABEL maintainer="student@example.com" \
      version="1.1" \
      description="Bookstore MySQL Database (Kubernetes Ready)"

# Copy initialization scripts
COPY init.sql /docker-entrypoint-initdb.d/

# Optional (documentation only)
EXPOSE 3306

# Healthcheck using application user (not root)
HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD mysqladmin ping \
      -h 127.0.0.1 \
      -u"${MYSQL_USER}" \
      -p"${MYSQL_PASSWORD}" || exit 1
