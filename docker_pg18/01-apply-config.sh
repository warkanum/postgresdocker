#!/bin/bash
set -e

echo "Setting up custom PostgreSQL configuration via include_dir..."

# Create config directory
mkdir -p "$PGDATA/conf.d"

# Copy custom config file
if [ -f /etc/postgresql/custom.conf ]; then
    cp /etc/postgresql/custom.conf "$PGDATA/conf.d/custom.conf"
    echo "Custom config copied to $PGDATA/conf.d/custom.conf"
fi

# Add include_dir directive to postgresql.conf
echo "include_dir = 'conf.d'" >> "$PGDATA/postgresql.conf"
echo "Added include_dir directive to postgresql.conf"

# Apply pg_hba.conf
if [ -f /etc/postgresql/pg_hba.conf ]; then
    cp /etc/postgresql/pg_hba.conf "$PGDATA/pg_hba.conf"
    echo "Custom pg_hba.conf applied"
fi

# Restart PostgreSQL to load shared_preload_libraries
echo "Restarting PostgreSQL to apply configuration..."
pg_ctl -D "$PGDATA" -m fast -w restart
echo "PostgreSQL restarted with custom configuration loaded"

# Restart to apply shared_preload_libraries
pg_ctl -D "$PGDATA" -m fast -w restart
