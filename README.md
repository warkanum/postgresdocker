# postgresdocker

Custom PostgreSQL container builds for South African deployments, release testing, and migration work. In other words: not just "run Postgres in Docker," but "run a PostgreSQL image with the locale, timezone, extensions, and operational defaults we actually care about."

Yes, this could all be a short README. It should not be. If someone lands here during a production scramble, they need answers, not a scavenger hunt.

## What This Repository Is

This repository packages PostgreSQL images with:

- South African locale support: `en_ZA.utf8`
- South African timezone defaults: `Africa/Johannesburg`
- Pre-installed database extensions for search, geospatial work, time-series, auditing, and general administration
- Container startup helpers and config files
- Docker and Podman compose files

The current focus is on modern PostgreSQL builds, especially:

- [`docker_pg18_za`](./docker_pg18_za/README.md): stable PostgreSQL 18 image
- [`docker_pg19_za_alpha`](./docker_pg19_za_alpha/README.md): PostgreSQL 19 alpha image for preview and experimentation

There are also older reference folders in the repo for historical or compatibility work:

- `legacy/officialpg12/`
- `legacy/C8/`

Those are useful context, but not the main line for current image work.

## Why This Exists

The original goal was to support environments migrating from older CentOS-based PostgreSQL installations while keeping a predictable containerized target. That means the repo is biased toward practical operations:

- familiar runtime defaults
- persistent storage mounts
- extension-heavy builds
- reproducible image publishing
- straightforward local testing

If your use case is "I need a stock Postgres with nothing interesting installed," the official images are excellent. If your use case is "I need a South Africa-oriented Postgres image with extra batteries already included," this repo is much closer to the point.

## Background Story

I've been compiling PostgreSQL for more than 10 years, and that history comes with a fairly impressive collection of environmental problems. Different operating systems, different upgrade paths, different packaging assumptions, and the usual parade of "this worked on the last machine" surprises all added friction over time. Moving between environments, from CentOS to other platforms and through repeated upgrade cycles, made one thing pretty clear: containerizing the database is usually the saner option.

That is the thinking behind this repository. Docker and Podman give us a far more predictable platform for running a PostgreSQL environment than repeated manual compilation on every host. So far, I have not seen a meaningful downside for the kinds of deployments this repo is aimed at. When the container is built cleanly and the runtime is tuned properly, PostgreSQL performs very well.

Not everyone agrees, of course. Some of my colleagues still prefer avoiding Docker or Podman, but for me the operational benefits outweigh the cost of maintaining manual compile processes over and over again. I do plan to add back manual compilation scripts for raw virtual machines, because sometimes reality insists on being inconvenient, but that is as far as I am willing to go.

## Repository Layout

| Path | Purpose |
|---|---|
| [`README.md`](./README.md) | Top-level project guide |
| [`DEV.md`](./DEV.md) | For the devs: release and maintainer workflow |
| [`Makefile`](./Makefile) | Root release tagging helpers |
| [`docker_pg18_za/`](./docker_pg18_za/README.md) | PostgreSQL 18 image, scripts, configs, compose files |
| [`docker_pg19_za_alpha/`](./docker_pg19_za_alpha/README.md) | PostgreSQL 19 alpha image, scripts, configs, compose files |
| `legacy/officialpg12/` | Older official PostgreSQL 12 reference materials |
| `legacy/C8/` | CentOS 8-era assets and experiments |

Each image directory is largely self-contained, with its own:

- `Dockerfile`
- `Makefile`
- `docker-compose.yml`
- `podman-compose.yml`
- initialization scripts
- PostgreSQL config files
- extension setup SQL
- image-specific README

## Image Variants

### PostgreSQL 18

The PostgreSQL 18 image is the primary maintained build in this repository.

See:

- [`docker_pg18_za/README.md`](./docker_pg18_za/README.md)
- [`docker_pg18_za/Extentions.md`](./docker_pg18_za/Extentions.md)
- [`docker_pg18_za/SSL_README.md`](./docker_pg18_za/SSL_README.md)

Highlights:

- based on `postgres:18-alpine`
- South African locale and timezone defaults
- extension-rich image for application, admin, analytics, and search use cases
- Docker Hub publishing flow tied to Git tags

### PostgreSQL 19 Alpha

The PostgreSQL 19 alpha image exists for forward-looking testing.

See:

- [`docker_pg19_za_alpha/README.md`](./docker_pg19_za_alpha/README.md)
- [`docker_pg19_za_alpha/Extentions.md`](./docker_pg19_za_alpha/Extentions.md)
- [`docker_pg19_za_alpha/SSL_README.md`](./docker_pg19_za_alpha/SSL_README.md)

Use it when you want to validate compatibility or try upcoming PostgreSQL behavior. Do not confuse "alpha" with "the thing we should casually throw at production and hope the universe is feeling generous."

## Common Defaults

The image directories expose similar defaults unless overridden through `.env` or runtime flags:

| Setting | Default |
|---|---|
| PostgreSQL user | `admin` |
| PostgreSQL password | `admin` |
| Default database | `root` |
| PostgreSQL port | `5432` |
| Locale | `en_ZA.utf8` |
| Timezone | `Africa/Johannesburg` |

Typical runtime override file:

```env
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin
POSTGRES_DB=root
PORT=5432
DOCKER_UID=70
DOCKER_GID=70
```

Check the image-specific `Makefile` and README before assuming every default is identical forever. Containers have a distressing habit of becoming "almost the same" over time.

For the devs working on release mechanics and repository-level publishing, see [`DEV.md`](./DEV.md).

## Quick Start

### Option 1: Work With PostgreSQL 18

```bash
cd docker_pg18_za
make build
make run
psql -h localhost -p 5432 -U admin -d root
```

### Option 2: Work With PostgreSQL 19 Alpha

```bash
cd docker_pg19_za_alpha
make build
make run
psql -h localhost -p 5432 -U admin -d root
```

### Option 3: Use Compose

From the relevant image directory:

```bash
docker compose up --build -d
```

Both compose files map the container port `5432` to host port `5403` by default, so connect accordingly if you use compose instead of the `make run` target.

## Local Development Workflow

The normal working pattern is:

1. Pick the image directory you care about.
2. Build the image locally.
3. Run the container with a mounted data directory.
4. Inspect logs, connect with `psql`, and validate extensions or application behavior.
5. Publish only after the image behaves like a civilized piece of infrastructure.

Example with PostgreSQL 18:

```bash
cd docker_pg18_za
make build
make run
make logs
make shell
make status
```

Useful targets in the image-level `Makefile` include:

- `make build`
- `make tag`
- `make push`
- `make push-skopeo`
- `make run`
- `make stop`
- `make restart`
- `make logs`
- `make shell`
- `make clean`
- `make status`

## Data Persistence

Persistent data is mounted from the host into `/var/lib/postgresql`.

Default host paths:

- PostgreSQL 18: `/tmp/postgresql18_za_data`
- PostgreSQL 19 alpha: `/tmp/postgresql19_za_alpha_data`

The image-level `make run` target creates the data directory if needed and mounts it into the container. For modern PostgreSQL layouts used here, the versioned data directory typically ends up under:

- `/var/lib/postgresql/18/docker`
- `/var/lib/postgresql/19/docker`

Useful path notes:

- PostgreSQL binaries such as `pg_archivecleanup` are available under `/usr/local/bin`
- Some helper scripts and SSL docs still reference `/var/lib/postgresql/data`
- The container runtime mount used by the image-level `Makefile` targets is `/var/lib/postgresql`

That distinction matters because the effective internal data location can differ slightly depending on which helper or compose path you are following. Naturally, nothing says "simple infrastructure" quite like two very similar directory conventions waiting for someone to mix them up.

If you are testing destructive initialization changes, use a disposable data directory. This is one of those lessons people only need to learn once, and preferably not at 2:00 a.m.

## Extensions

The active images ship with a broad extension set. Depending on the image version, this includes tools such as:

- `pgvector`
- `postgis`
- `pgrouting`
- `timescaledb`
- `pg_search`
- `pg_textsearch`
- `pg_jsonschema`
- `pg_stat_statements`
- `pg_cron`
- `pg_qualstats`
- `pgaudit`
- `pg_partman`
- `pg_background`
- `pg_repack`
- `http`
- `plpython3u`
- `pgcrypto`
- `uuid-ossp`
- `pg_trgm`
- `hstore`
- `citext`
- `amcheck`
- `pgstattuple`
- `postgres_fdw`
- `unaccent`

For detailed extension notes, use the image-specific documentation:

- [`docker_pg18_za/Extentions.md`](./docker_pg18_za/Extentions.md)
- [`docker_pg19_za_alpha/Extentions.md`](./docker_pg19_za_alpha/Extentions.md)

Also worth noting: `plv8` is present in comments in the Dockerfiles but is not currently enabled in the built images.

## SSL

Both active image directories include SSL helper material and certificate-generation scripts:

- [`docker_pg18_za/generate-ssl-certs.sh`](./docker_pg18_za/generate-ssl-certs.sh)
- [`docker_pg18_za/SSL_README.md`](./docker_pg18_za/SSL_README.md)
- [`docker_pg19_za_alpha/generate-ssl-certs.sh`](./docker_pg19_za_alpha/generate-ssl-certs.sh)
- [`docker_pg19_za_alpha/SSL_README.md`](./docker_pg19_za_alpha/SSL_README.md)

Read the image-specific SSL guide before assuming the certificates or trust model match your deployment requirements. Self-signed is fine for local or controlled use. It is less fine when auditors begin asking thoughtful questions.

## Docker Hub Images

Published image names include:

- `docker.io/warkanum/postgresql18_za`
- `docker.io/warkanum/postgresql19_za_alpha`

Example pull:

```bash
docker pull warkanum/postgresql18_za:latest
docker run -d -p 5432:5432 --env-file .env --name pg18za warkanum/postgresql18_za:latest
```

## Podman

Each active image directory includes a `podman-compose.yml` file alongside the Docker compose file. If your environment uses Podman instead of Docker, start in the corresponding directory and inspect the compose and `Makefile` settings there before running.

The repo clearly intends to support both toolchains. Because of course one container runtime was not enough drama for one project.

## Notes And Caveats

- The top-level release automation now covers both active image lines: PostgreSQL 18 and PostgreSQL 19 alpha.
- Compose defaults and `make run` defaults are not identical; compose maps host port `5403`, while `make run` uses `5432` unless overridden.
- The `legacy/` directory contains historical reference material rather than the mainline path for current releases.
- The file `Extentions.md` is spelled that way in the repository. No, I am not thrilled either, but the documentation should match the actual path.

## Recommended Starting Points

If you are new to the repo, start here:

1. Read [`docker_pg18_za/README.md`](./docker_pg18_za/README.md).
2. Review the available extensions in [`docker_pg18_za/Extentions.md`](./docker_pg18_za/Extentions.md).
3. Build and run the PostgreSQL 18 image locally.
4. Use the root [`Makefile`](./Makefile) only when you are ready to create a repository release tag.

That should get you productive without needing to reverse-engineer the entire structure while the clock is ticking and reality is being uncooperative.
