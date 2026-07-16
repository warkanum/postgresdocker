VERSION ?=

PG18_LATEST_TAG := $(shell git tag --list 'pg18-v*' --sort=-version:refname | awk '/^pg18-v[0-9]+\.[0-9]+\.[0-9]+$$/ { print; exit }')
PG18_NEXT_VERSION := $(if $(PG18_LATEST_TAG),$(shell printf '%s\n' '$(PG18_LATEST_TAG)' | awk -F. '{ sub(/^pg18-v/, "", $$1); printf "v%d.%d.%d\n", $$1, $$2, $$3 + 1 }'),v1.0.0)
PG18_RELEASE_VERSION := $(if $(strip $(VERSION)),$(if $(filter v%,$(strip $(VERSION))),$(strip $(VERSION)),v$(strip $(VERSION))),$(PG18_NEXT_VERSION))
PG18_RELEASE_TAG := pg18-$(PG18_RELEASE_VERSION)

PG19_LATEST_TAG := $(shell git tag --list 'pg19-alpha-v*' --sort=-version:refname | awk '/^pg19-alpha-v[0-9]+\.[0-9]+\.[0-9]+$$/ { print; exit }')
PG19_NEXT_VERSION := $(if $(PG19_LATEST_TAG),$(shell printf '%s\n' '$(PG19_LATEST_TAG)' | awk -F. '{ sub(/^pg19-alpha-v/, "", $$1); printf "v%d.%d.%d\n", $$1, $$2, $$3 + 1 }'),v0.1.0)
PG19_RELEASE_VERSION := $(if $(strip $(VERSION)),$(if $(filter v%,$(strip $(VERSION))),$(strip $(VERSION)),v$(strip $(VERSION))),$(PG19_NEXT_VERSION))
PG19_RELEASE_TAG := pg19-alpha-$(PG19_RELEASE_VERSION)

.PHONY: help version version-pg18 version-pg19 validate-release-pg18 validate-release-pg19 release-pg18 release-pg19

help:
	@printf '%s\n' \
		'Release targets:' \
		'  make version                         Preview both next release tags' \
		'  make release-pg18                    Create and push the next PG18 release' \
		'  make release-pg18 VERSION=v2.0.0     Create and push a specific PG18 release' \
		'  make release-pg19                    Create and push the next PG19 alpha release' \
		'  make release-pg19 VERSION=v0.2.0     Create and push a specific PG19 alpha release'

version: version-pg18 version-pg19

version-pg18:
	@printf '%s\n' '$(PG18_RELEASE_TAG)'

version-pg19:
	@printf '%s\n' '$(PG19_RELEASE_TAG)'

validate-release-pg18:
	@printf '%s\n' '$(PG18_RELEASE_VERSION)' | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$$' || { \
		printf 'ERROR: VERSION must use vX.Y.Z format (received: %s)\n' '$(PG18_RELEASE_VERSION)' >&2; \
		exit 1; \
	}
	@if git rev-parse --verify --quiet 'refs/tags/$(PG18_RELEASE_TAG)' >/dev/null; then \
		printf 'ERROR: Tag %s already exists\n' '$(PG18_RELEASE_TAG)' >&2; \
		exit 1; \
	fi

validate-release-pg19:
	@printf '%s\n' '$(PG19_RELEASE_VERSION)' | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$$' || { \
		printf 'ERROR: VERSION must use vX.Y.Z format (received: %s)\n' '$(PG19_RELEASE_VERSION)' >&2; \
		exit 1; \
	}
	@if git rev-parse --verify --quiet 'refs/tags/$(PG19_RELEASE_TAG)' >/dev/null; then \
		printf 'ERROR: Tag %s already exists\n' '$(PG19_RELEASE_TAG)' >&2; \
		exit 1; \
	fi

release-pg18: validate-release-pg18
	@printf 'Creating release %s\n' '$(PG18_RELEASE_TAG)'
	git tag -a '$(PG18_RELEASE_TAG)' -m 'Release $(PG18_RELEASE_TAG)'
	git push origin '$(PG18_RELEASE_TAG)'
	@printf 'Released %s; the PG18 GitHub workflow will build image tag %s.\n' '$(PG18_RELEASE_TAG)' '$(PG18_RELEASE_VERSION)'

release-pg19: validate-release-pg19
	@printf 'Creating release %s\n' '$(PG19_RELEASE_TAG)'
	git tag -a '$(PG19_RELEASE_TAG)' -m 'Release $(PG19_RELEASE_TAG)'
	git push origin '$(PG19_RELEASE_TAG)'
	@printf 'Released %s; the PG19 GitHub workflow will build image tag %s.\n' '$(PG19_RELEASE_TAG)' '$(PG19_RELEASE_VERSION)'
