# PostgreSQL source installations

This Ansible project installs PostgreSQL from the upstream source tarball on Arch, Gentoo, AlmaLinux, CentOS Stream, Ubuntu, and Void Linux. It is version-parameterized: PostgreSQL 18.4 is the default, but changing `postgresql_version` is enough to build another supported upstream release.

Every installation is isolated from distribution PostgreSQL packages: its operating-system and database superuser defaults to `pgsql`, its operating-system home defaults to `/home/pgsql` (`postgresql_service_home`), its data directory defaults to `/var/lib/pgsql/<major>/data`, and its service name defaults to `pgza_<major>` (for example, `pgza_18.service`). Override these `postgresql_service_*` variables only when deploying a separate isolated instance.

System services use systemd where available, OpenRC on Gentoo/OpenRC hosts, and runit on Void Linux. The service name remains `pgza_<major>` on every init system.

## Quick start

```bash
cd ansible
cp inventories/hosts.example.yml inventories/hosts.yml
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml -e postgresql_version=18.4
```

The default is PostgreSQL 18.4 with its upstream SHA-256. Set a matching checksum whenever selecting another version; the source archive is verified before extraction.

```yaml
# inventories/group_vars/postgresql_linux.yml
postgresql_version: "17.6"
postgresql_source_sha256: "<sha256 from postgresql.org>"
postgresql_extension_profile: full
```

## Profiles

- `core` builds PostgreSQL, contrib, SSL, ICU, XML/XSLT, Perl, Python, LZ4, and Zstandard.
- `full` mirrors the extension catalogue used by `docker_pg18_za`: pgvector, PostGIS, pgRouting, TimescaleDB, pgsql-http, pg_cron, pg_partman, pgaudit, pg_repack, pg_qualstats, pg_background, pg_search, pg_textsearch, and pg_jsonschema. `plv8` is excluded because it is also commented out in the Docker image.
- Rust/pgrx extensions are enabled by the full profile and use the same pgrx versions as the Docker build. They are the most version-sensitive part of the stack, so pin and test them again whenever changing the PostgreSQL major.

For an older PostgreSQL major, start with `postgresql_extension_profile: core`, then provide a tested `postgresql_extensions` and `postgresql_pgrx_extensions` catalogue for that major. The role omits modern LZ4 and Zstandard configure flags where the selected PostgreSQL source version does not support them.

The role creates the Docker profile's enabled extensions in `postgresql_initial_database` (default `pgsql`). Set `postgresql_create_extensions: false` to install the binaries only, or change that database name for a dedicated bootstrap database.

## Windows

`postgresql_windows` is an unofficial, best-effort profile. It creates the dedicated local `pgsql` service account, installs the service as `pgza_18` by default, and uses `pgsql` as its database superuser. It enables compatible bundled extensions (`pgcrypto`, `pg_trgm`, `uuid-ossp`, `hstore`, `citext`, and related contrib modules) but intentionally does not compile Linux-only extensions or preload libraries.

Provide a valid `postgresql_windows_installer_url` and `postgresql_windows_installer_checksum`; upstream installer URLs and filenames are version-specific. For unsupported extensions, run a Linux host or container instead.
