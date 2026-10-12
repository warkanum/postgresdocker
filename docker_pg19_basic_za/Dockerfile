# Use the official PostgreSQL image with Alpine Linux as the base image
# Basic variant: TimescaleDB, pg_textsearch, PostGIS and pgRouting are left out
# (no or beta PG19 support upstream, or heavy GDAL/PROJ/GEOS/Boost builds).
# PostgreSQL 19 is still in beta upstream; switch to 19-alpine once it is GA
ARG PG_IMAGE_TAG=19beta4-alpine
FROM docker.io/library/postgres:${PG_IMAGE_TAG} as pgdocker-base

# Set the timezone to Africa/Johannesburg
ENV TZ=Africa/Johannesburg

# Set the locale to en_ZA.utf8 directly in the environment variables
ENV LANG=en_ZA.utf8
ENV LC_ALL=en_ZA.utf8

# Install additional extensions and dependencies
RUN apk add --no-cache \
    postgresql-contrib \
    postgresql-dev \
    wget \
    tar \
    perl \
    git \
    python3 \
    build-base \
    py3-pip \
    postgresql-jit \
    libreoffice \
    cmake \
    clang \
    llvm \
    llvm-dev \
    openssl \
    musl-locales \
    tzdata

# Install pgvector extension (main branch for PG19 compatibility)
RUN mkdir -p /usr/lib/llvm19/bin /usr/lib/llvm21/bin \
    && for f in /usr/bin/llvm-*; do \
        ln -sf "$f" /usr/lib/llvm19/bin/"$(basename "$f")"; \
        ln -sf "$f" /usr/lib/llvm21/bin/"$(basename "$f")"; \
    done \
    && ln -sf /usr/bin/clang /usr/bin/clang-19 \
    && ln -sf /usr/bin/clang /usr/bin/clang-21 \
    && cd /tmp \
    && git clone https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pgvector

# Install pgsql-http extension
RUN apk add --no-cache curl-dev openssl-dev \
    && cd /tmp \
    && git clone https://github.com/pramsey/pgsql-http.git \
    && cd pgsql-http \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pgsql-http

# Install pg_cron extension
RUN apk add --no-cache gettext-dev \
    && cd /tmp \
    && git clone https://github.com/citusdata/pg_cron.git \
    && cd pg_cron \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_cron

# Install pg_partman extension
RUN cd /tmp \
    && git clone https://github.com/pgpartman/pg_partman.git \
    && cd pg_partman \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_partman

# Install pgaudit extension
RUN apk add --no-cache krb5-dev \
    && cd /tmp \
    && git clone --branch REL_19_STABLE --depth 1 https://github.com/pgaudit/pgaudit.git \
    && cd pgaudit \
    && make USE_PGXS=1 \
    && make USE_PGXS=1 install \
    && cd / \
    && rm -rf /tmp/pgaudit

# Install pg_repack extension
RUN apk add --no-cache zlib-dev lz4-dev \
    && cd /tmp \
    && git clone https://github.com/reorg/pg_repack.git \
    && cd pg_repack \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_repack

# Install pg_qualstats extension
RUN cd /tmp \
    && git clone https://github.com/powa-team/pg_qualstats.git \
    && cd pg_qualstats \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_qualstats

# Install pg_background extension
RUN cd /tmp \
    && git clone https://github.com/vibhorkum/pg_background.git \
    && cd pg_background \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_background

RUN apk add --no-cache python3-dev g++ gcc unixodbc-dev unixodbc musl-dev freetds-dev freetds libmagic

RUN apk add --no-cache py3-html5lib py3-beautifulsoup4 py3-numpy py3-paramiko py3-psycopg2 py3-openssl py3-pypdf \
    py3-yaml py3-urllib3 py3-reportlab py3-mimeparse py3-num2words py3-rsa py3-pillow py3-openpyxl py3-lxml \
    py3-pycryptodome py3-requests py3-psutil

# Install the plv8 extension (v3.2.4)
# RUN cd /tmp \
#     && git clone --branch v3.2.4 --depth 1 https://github.com/plv8/plv8.git \
#     && cd plv8 \
#     && make \
#     && make install \
#     && cd / \
#     && rm -rf /tmp/plv8

FROM pgdocker-base

# Remap postgres user to match host user (for proper file permissions)
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000
RUN deluser postgres && \
    addgroup -g ${DOCKER_GID} postgres && \
    adduser -D -u ${DOCKER_UID} -G postgres postgres && \
    mkdir -p /var/lib/postgresql /var/run/postgresql && \
    chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql && \
    chmod 775 /var/run/postgresql


# Create Python virtual environment (outside data volume so it persists)
RUN python3 -m venv --system-site-packages /opt/python_env

# Install Python 3 deps into the venv
RUN /opt/python_env/bin/pip install --upgrade pip \
    && /opt/python_env/bin/pip install \
    beautifulsoup4 chardet numpy openpyxl pdfminer3k pillow \
    psycopg2 PyPDF2 pymssql python-docx python-magic requests \
    scipy scp suds-community num2words \
    && chown -R postgres:postgres /opt/python_env

# Make the venv accessible to PostgreSQL / PL/Python
ENV VIRTUAL_ENV=/opt/python_env
ENV PATH="/opt/python_env/bin:$PATH"
ENV PYTHONPATH=/opt/python_env/lib/python3.12/site-packages


# Set environment variables for PostgreSQL (defaults from official image, override via docker-compose)
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password
ENV POSTGRES_DB=postgres

# Initialize the data directory if not initialized
#COPY init-db.sh /docker-entrypoint-initdb.d/init-db.sh
#RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh

# Copy SQL init script to create extensions on first startup
COPY init-extensions.sql /docker-entrypoint-initdb.d/00-init-extensions.sql



# Copy setup script
COPY setup-python-env.sh /docker-entrypoint-initdb.d/setup-python-env.sh
RUN chmod +x /docker-entrypoint-initdb.d/setup-python-env.sh



# Use a volume for the data directory (PG19+ uses version-specific subdirectories)
VOLUME /var/lib/postgresql

# Copy custom config files into image. Alpine packages may leave
# /etc/postgresql as a symlink to /etc/postgresql19, with the real directory
# owned by uid/gid 70 and mode 750. The image remaps postgres to DOCKER_UID
# above, so fix both possible paths explicitly instead of relying on recursive
# chown/chmod symlink traversal semantics. Without this, 01-apply-config.sh
# can't read custom.conf at container startup and the container exits on first
# boot.
COPY custom.conf /etc/postgresql/custom.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf
RUN for dir in /etc/postgresql /etc/postgresql19; do \
        if [ -e "$dir" ]; then \
            chown -R postgres:postgres "$dir" && chmod 755 "$dir"; \
        fi; \
    done \
    && chmod 644 /etc/postgresql/custom.conf /etc/postgresql/pg_hba.conf

# Copy SSL certificate generation script
COPY generate-ssl-certs.sh /usr/local/bin/generate-ssl-certs.sh
RUN chmod +x /usr/local/bin/generate-ssl-certs.sh

# Generate SSL certificates at build time in non-volume location
RUN /usr/local/bin/generate-ssl-certs.sh /etc/ssl/postgresql && \
    chown -R postgres:postgres /etc/ssl/postgresql

# Copy init script that applies config on first startup (runs before extensions)
COPY 01-apply-config.sh /docker-entrypoint-initdb.d/00-00-apply-config.sh
RUN chmod +x /docker-entrypoint-initdb.d/00-00-apply-config.sh

RUN chown postgres:postgres -R /var/run/postgresql
# Expose the PostgreSQL port
EXPOSE 5432
