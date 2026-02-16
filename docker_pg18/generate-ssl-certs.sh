#!/bin/bash
set -e

# Generate self-signed SSL certificate for PostgreSQL
# This script creates a certificate valid for 10 years
# Usage: generate-ssl-certs.sh [ssl_directory]

SSL_DIR="${1:-/etc/ssl/postgresql}"
CERT_FILE="${SSL_DIR}/server.crt"
KEY_FILE="${SSL_DIR}/server.key"

echo "Generating self-signed SSL certificate for PostgreSQL..."

# Create SSL directory if it doesn't exist
mkdir -p "${SSL_DIR}"

# Generate private key and certificate in one command
openssl req -new -x509 -days 3650 -nodes -text \
    -out "${CERT_FILE}" \
    -keyout "${KEY_FILE}" \
    -subj "/C=ZA/ST=Gauteng/L=Johannesburg/O=PostgreSQL/OU=Database/CN=pgsql18.local"

# Set proper permissions (PostgreSQL requires strict permissions on key file)
chmod 600 "${KEY_FILE}"
chmod 644 "${CERT_FILE}"

echo "SSL certificate generated successfully:"
echo "  Certificate: ${CERT_FILE}"
echo "  Private Key: ${KEY_FILE}"
echo ""
echo "Certificate details:"
openssl x509 -in "${CERT_FILE}" -text -noout | grep -E "Subject:|Issuer:|Not Before|Not After"
