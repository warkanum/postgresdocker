#!/usr/bin/env python3
"""Static regression checks for auto-generated SSL certificate handling.

Both active image directories (PostgreSQL 18 and PostgreSQL 19 alpha) ship an
``01-apply-config.sh`` entrypoint that copies build-time self-signed
certificates into the data directory at first boot. These checks pin the
guarantees that keep ``ssl=on`` reliably loadable at runtime:

* certificates are copied from the build-time ``/etc/ssl/postgresql`` location;
* the data-directory ``ssl`` path is ``chown``ed to the runtime postgres user
  so a volume owned by a different uid cannot block key loading;
* the key keeps ``0600`` and the cert keeps ``0644`` permissions;
* the runtime ``ssl_cert_file``/``ssl_key_file`` paths are rewritten to the
  data directory via the ``sed`` substitution in the apply-config script.

Mirrors the existing ``test_boot_permissions.py`` convention: plain asserts,
no third-party test framework required.
"""

from pathlib import Path

IMAGES = [
    Path(__file__).resolve().parents[2] / "docker_pg18_za",
    Path(__file__).resolve().parents[2] / "docker_pg19_za_alpha",
]


def _apply_config(image_dir: Path) -> str:
    path = image_dir / "01-apply-config.sh"
    assert path.exists(), f"{path} is missing"
    return path.read_text(encoding="utf-8")


def test_ssl_certs_are_copied_from_build_time_location() -> None:
    for image_dir in IMAGES:
        text = _apply_config(image_dir)
        assert "/etc/ssl/postgresql/server.crt" in text
        assert "/etc/ssl/postgresql/server.key" in text
        assert '"$SSL_DIR/server.crt"' in text
        assert '"$SSL_DIR/server.key"' in text


def test_ssl_directory_is_chowned_to_runtime_postgres_user() -> None:
    for image_dir in IMAGES:
        text = _apply_config(image_dir)
        # The runtime postgres user must own the copied certs, otherwise a data
        # volume owned by a different uid makes postgres refuse to load server.key.
        assert "chown -R postgres:postgres" in text
        assert '"$SSL_DIR"' in text


def test_ssl_key_permissions_are_strict() -> None:
    for image_dir in IMAGES:
        text = _apply_config(image_dir)
        assert 'chmod 600 "$SSL_DIR/server.key"' in text
        assert 'chmod 644 "$SSL_DIR/server.crt"' in text


def test_ssl_config_paths_are_rewritten_to_data_directory() -> None:
    for image_dir in IMAGES:
        text = _apply_config(image_dir)
        # custom.conf ships with /var/lib/postgresql/ssl paths; the entrypoint
        # rewrites them to the runtime $PGDATA/ssl path at first boot.
        assert "/var/lib/postgresql/ssl" in text
        assert f'sed -i "s|/var/lib/postgresql/ssl|$PGDATA/ssl|g"' in text


def main() -> None:
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            fn()
            print(f"PASS: {name}")


if __name__ == "__main__":
    main()
    print("ssl cert setup checks passed")
