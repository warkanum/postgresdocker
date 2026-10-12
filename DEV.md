# For the devs

This file is for maintainers and release work. The main [`README.md`](./README.md) stays focused on what the project is, why it exists, and how to use the images without making everyone wade through tagging mechanics.

## Release Workflow

The root [`Makefile`](./Makefile) manages repository release tags for the active image lines.

Current release families:

- PostgreSQL 17 uses tags like `pg17-v1.2.3`
- PostgreSQL 18 uses tags like `pg18-v1.2.3`
- PostgreSQL 18 VectorChord uses tags like `pg18vc-v1.2.3`
- PostgreSQL 19 uses tags like `pg19-v1.2.3`
- PostgreSQL 19 Basic uses tags like `pg19basic-v1.2.3`

## Preview The Next Release Tags

To preview all next tags:

```bash
make version
```

To preview one track only:

```bash
make version-pg17
make version-pg18
make version-pg18vc
make version-pg19
make version-pg19basic
```

The `Makefile` inspects existing tags and increments the patch version automatically.

Default starting points:

- PG17 starts at `v1.0.0` if no matching tags exist
- PG18 starts at `v1.0.0` if no matching tags exist
- PG18 VectorChord starts at `v1.0.0` if no matching tags exist
- PG19 starts at `v1.0.0` if no matching tags exist
- PG19 Basic starts at `v1.0.0` if no matching tags exist

## Create And Push A Release

For PostgreSQL 17:

```bash
make release-pg17
```

For PostgreSQL 18:

```bash
make release-pg18
```

For PostgreSQL 18 VectorChord:

```bash
make release-pg18vc
```

For PostgreSQL 19:

```bash
make release-pg19
```

For PostgreSQL 19 Basic:

```bash
make release-pg19basic
```

Each target will:

1. calculate the next version
2. validate the `vX.Y.Z` version format
3. fail if the full release tag already exists
4. create an annotated Git tag
5. push that tag to `origin`

## Override The Version

You can supply a specific version explicitly.

Examples:

```bash
make release-pg17 VERSION=v2.0.0
make release-pg18 VERSION=v2.0.0
make release-pg18vc VERSION=v2.0.0
make release-pg19 VERSION=v2.0.0
make release-pg19basic VERSION=v2.0.0
```

Providing `VERSION=2.0.0` also works; the `Makefile` normalizes it to `v2.0.0`.

## What Happens After Tag Push

Pushing a release tag triggers the matching GitHub Actions workflow for that image line.

- `release-pg17` triggers the PostgreSQL 17 workflow and publishes the image using the matching version
- `release-pg18` triggers the PostgreSQL 18 workflow and publishes the image using the matching version
- `release-pg18vc` triggers the PostgreSQL 18 VectorChord workflow and publishes the image using the matching version
- `release-pg19` triggers the PostgreSQL 19 workflow and publishes the image using the matching version
- `release-pg19basic` triggers the PostgreSQL 19 Basic workflow and publishes the image using the matching version

## Helpful Commands

Show the release helper text:

```bash
make help
```

Inspect the root `Makefile` if you need the exact tag naming and validation logic:

- [`Makefile`](./Makefile)

## Path Notes

Useful internal PostgreSQL paths that come up during debugging and maintenance:

- PostgreSQL utilities such as `pg_archivecleanup` live under `/usr/local/bin`
- Some scripts and SSL notes refer to `/var/lib/postgresql/data`
- The image-level `make run` targets mount the host data directory into `/var/lib/postgresql`
- PostgreSQL 17 uses `PGDATA=/var/lib/postgresql/data` directly; its `make run` and compose files mount there
- For PostgreSQL 18 and newer layouts in this repo, versioned data commonly ends up under paths like `/var/lib/postgresql/data/18/docker`

If you are tracing a startup issue, certificate path, or data-directory mismatch, check whether the script you are reading assumes `/var/lib/postgresql` or `/var/lib/postgresql/data`. They are related, but they are not interchangeable in every context, because apparently consistency was too easy.

## Notes

- Use the root `Makefile` for repository-level releases.
- The image-level `Makefile` files are for local image build and runtime tasks.
- If you are just trying to run PostgreSQL locally, go back to [`README.md`](./README.md). This file is not your first stop unless you enjoy release plumbing for recreational purposes.
