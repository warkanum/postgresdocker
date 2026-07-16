# For the devs

This file is for maintainers and release work. The main [`README.md`](./README.md) stays focused on what the project is, why it exists, and how to use the images without making everyone wade through tagging mechanics.

## Release Workflow

The root [`Makefile`](./Makefile) manages repository release tags for the active image lines.

Current release families:

- PostgreSQL 18 uses tags like `pg18-v1.2.3`
- PostgreSQL 19 alpha uses tags like `pg19-alpha-v0.2.0`

## Preview The Next Release Tags

To preview both next tags:

```bash
make version
```

To preview one track only:

```bash
make version-pg18
make version-pg19
```

The `Makefile` inspects existing tags and increments the patch version automatically.

Default starting points:

- PG18 starts at `v1.0.0` if no matching tags exist
- PG19 alpha starts at `v0.1.0` if no matching tags exist

## Create And Push A Release

For PostgreSQL 18:

```bash
make release-pg18
```

For PostgreSQL 19 alpha:

```bash
make release-pg19
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
make release-pg18 VERSION=v2.0.0
make release-pg19 VERSION=v0.2.0
```

Providing `VERSION=2.0.0` also works; the `Makefile` normalizes it to `v2.0.0`.

## What Happens After Tag Push

Pushing a release tag triggers the matching GitHub Actions workflow for that image line.

- `release-pg18` triggers the PostgreSQL 18 workflow and publishes the image using the matching version
- `release-pg19` triggers the PostgreSQL 19 alpha workflow and publishes the image using the matching version

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
- For PostgreSQL 18 and newer layouts in this repo, versioned data commonly ends up under paths like `/var/lib/postgresql/data/18/docker`

If you are tracing a startup issue, certificate path, or data-directory mismatch, check whether the script you are reading assumes `/var/lib/postgresql` or `/var/lib/postgresql/data`. They are related, but they are not interchangeable in every context, because apparently consistency was too easy.

## Notes

- Use the root `Makefile` for repository-level releases.
- The image-level `Makefile` files are for local image build and runtime tasks.
- If you are just trying to run PostgreSQL locally, go back to [`README.md`](./README.md). This file is not your first stop unless you enjoy release plumbing for recreational purposes.
