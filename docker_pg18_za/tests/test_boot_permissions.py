#!/usr/bin/env python3
"""Static regression checks for PostgreSQL 18 image boot permissions."""

from pathlib import Path
import re

DOCKERFILE = Path(__file__).resolve().parents[1] / "Dockerfile"


def _dockerfile_text() -> str:
    return DOCKERFILE.read_text(encoding="utf-8")


def test_postgresql_config_permissions_are_fixed_for_remapped_postgres_user() -> None:
    text = _dockerfile_text()

    assert "ARG DOCKER_UID=1000" in text
    assert "adduser -D -u ${DOCKER_UID} -G postgres postgres" in text
    assert "COPY custom.conf /etc/postgresql/custom.conf" in text
    assert "COPY pg_hba.conf /etc/postgresql/pg_hba.conf" in text

    copy_index = text.index("COPY custom.conf /etc/postgresql/custom.conf")
    permission_fix_index = text.index("RUN for dir in /etc/postgresql /etc/postgresql18")
    entrypoint_index = text.index("COPY 01-apply-config.sh")

    assert copy_index < permission_fix_index < entrypoint_index
    assert re.search(r"for dir in /etc/postgresql /etc/postgresql18; do", text)
    assert "chown -R postgres:postgres \"$dir\"" in text
    assert "chmod 755 \"$dir\"" in text
    assert "chmod 644 /etc/postgresql/custom.conf /etc/postgresql/pg_hba.conf" in text


if __name__ == "__main__":
    test_postgresql_config_permissions_are_fixed_for_remapped_postgres_user()
    print("boot permission checks passed")
