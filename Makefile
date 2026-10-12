VERSION ?=

PG17_LATEST_TAG := $(shell git tag --list 'pg17-v*' --sort=-version:refname | awk '/^pg17-v[0-9]+\.[0-9]+\.[0-9]+$$/ { print; exit }')
PG17_NEXT_VERSION := $(if $(PG17_LATEST_TAG),$(shell printf '%s\n' '$(PG17_LATEST_TAG)' | awk -F. '{ sub(/^pg17-v/, "", $$1); printf "v%d.%d.%d\n", $$1, $$2, $$3 + 1 }'),v1.0.0)
PG17_RELEASE_VERSION := $(if $(strip $(VERSION)),$(if $(filter v%,$(strip $(VERSION))),$(strip $(VERSION)),v$(strip $(VERSION))),$(PG17_NEXT_VERSION))
PG17_RELEASE_TAG := pg17-$(PG17_RELEASE_VERSION)

PG18_LATEST_TAG := $(shell git tag --list 'pg18-v*' --sort=-version:refname | awk '/^pg18-v[0-9]+\.[0-9]+\.[0-9]+$$/ { print; exit }')
PG18_NEXT_VERSION := $(if $(PG18_LATEST_TAG),$(shell printf '%s\n' '$(PG18_LATEST_TAG)' | awk -F. '{ sub(/^pg18-v/, "", $$1); printf "v%d.%d.%d\n", $$1, $$2, $$3 + 1 }'),v1.0.0)
PG18_RELEASE_VERSION := $(if $(strip $(VERSION)),$(if $(filter v%,$(strip $(VERSION))),$(strip $(VERSION)),v$(strip $(VERSION))),$(PG18_NEXT_VERSION))
PG18_RELEASE_TAG := pg18-$(PG18_RELEASE_VERSION)

PG18VC_LATEST_TAG := $(shell git tag --list 'pg18vc-v*' --sort=-version:refname | awk '/^pg18vc-v[0-9]+\.[0-9]+\.[0-9]+$$/ { print; exit }')
PG18VC_NEXT_VERSION := $(if $(PG18VC_LATEST_TAG),$(shell printf '%s\n' '$(PG18VC_LATEST_TAG)' | awk -F. '{ sub(/^pg18vc-v/, "", $$1); printf "v%d.%d.%d\n", $$1, $$2, $$3 + 1 }'),v1.0.0)
PG18VC_RELEASE_VERSION := $(if $(strip $(VERSION)),$(if $(filter v%,$(strip $(VERSION))),$(strip $(VERSION)),v$(strip $(VERSION))),$(PG18VC_NEXT_VERSION))
PG18VC_RELEASE_TAG := pg18vc-$(PG18VC_RELEASE_VERSION)

PG19_LATEST_TAG := $(shell git tag --list 'pg19-v*' --sort=-version:refname | awk '/^pg19-v[0-9]+\.[0-9]+\.[0-9]+$$/ { print; exit }')
PG19_NEXT_VERSION := $(if $(PG19_LATEST_TAG),$(shell printf '%s\n' '$(PG19_LATEST_TAG)' | awk -F. '{ sub(/^pg19-v/, "", $$1); printf "v%d.%d.%d\n", $$1, $$2, $$3 + 1 }'),v1.0.0)
PG19_RELEASE_VERSION := $(if $(strip $(VERSION)),$(if $(filter v%,$(strip $(VERSION))),$(strip $(VERSION)),v$(strip $(VERSION))),$(PG19_NEXT_VERSION))
PG19_RELEASE_TAG := pg19-$(PG19_RELEASE_VERSION)

PG19BASIC_LATEST_TAG := $(shell git tag --list 'pg19basic-v*' --sort=-version:refname | awk '/^pg19basic-v[0-9]+\.[0-9]+\.[0-9]+$$/ { print; exit }')
PG19BASIC_NEXT_VERSION := $(if $(PG19BASIC_LATEST_TAG),$(shell printf '%s\n' '$(PG19BASIC_LATEST_TAG)' | awk -F. '{ sub(/^pg19basic-v/, "", $$1); printf "v%d.%d.%d\n", $$1, $$2, $$3 + 1 }'),v1.0.0)
PG19BASIC_RELEASE_VERSION := $(if $(strip $(VERSION)),$(if $(filter v%,$(strip $(VERSION))),$(strip $(VERSION)),v$(strip $(VERSION))),$(PG19BASIC_NEXT_VERSION))
PG19BASIC_RELEASE_TAG := pg19basic-$(PG19BASIC_RELEASE_VERSION)

.PHONY: help version version-pg17 version-pg18 version-pg18vc version-pg19 version-pg19basic validate-release-pg17 validate-release-pg18 validate-release-pg18vc validate-release-pg19 validate-release-pg19basic release-pg17 release-pg18 release-pg18vc release-pg19 release-pg19basic

help:
	@printf '%s\n' \
		'Release targets:' \
		'  make version                         Preview all next release tags' \
		'  make release-pg17                    Create and push the next PG17 release' \
		'  make release-pg17 VERSION=v2.0.0     Create and push a specific PG17 release' \
		'  make release-pg18                    Create and push the next PG18 release' \
		'  make release-pg18 VERSION=v2.0.0     Create and push a specific PG18 release' \
		'  make release-pg18vc                  Create and push the next PG18 VectorChord release' \
		'  make release-pg18vc VERSION=v2.0.0   Create and push a specific PG18 VectorChord release' \
		'  make release-pg19                    Create and push the next PG19 release' \
		'  make release-pg19 VERSION=v1.0.1     Create and push a specific PG19 release' \
		'  make release-pg19basic               Create and push the next PG19 Basic release' \
		'  make release-pg19basic VERSION=v1.0.1 Create and push a specific PG19 Basic release'

version: version-pg17 version-pg18 version-pg18vc version-pg19 version-pg19basic

version-pg17:
	@printf '%s\n' '$(PG17_RELEASE_TAG)'

version-pg18:
	@printf '%s\n' '$(PG18_RELEASE_TAG)'

version-pg18vc:
	@printf '%s\n' '$(PG18VC_RELEASE_TAG)'

version-pg19:
	@printf '%s\n' '$(PG19_RELEASE_TAG)'

version-pg19basic:
	@printf '%s\n' '$(PG19BASIC_RELEASE_TAG)'


validate-release-pg17:
	@printf '%s\n' '$(PG17_RELEASE_VERSION)' | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$$' || { \
		printf 'ERROR: VERSION must use vX.Y.Z format (received: %s)\n' '$(PG17_RELEASE_VERSION)' >&2; \
		exit 1; \
	}
	@if git rev-parse --verify --quiet 'refs/tags/$(PG17_RELEASE_TAG)' >/dev/null; then \
		printf 'ERROR: Tag %s already exists\n' '$(PG17_RELEASE_TAG)' >&2; \
		exit 1; \
	fi

validate-release-pg18:
	@printf '%s\n' '$(PG18_RELEASE_VERSION)' | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$$' || { \
		printf 'ERROR: VERSION must use vX.Y.Z format (received: %s)\n' '$(PG18_RELEASE_VERSION)' >&2; \
		exit 1; \
	}
	@if git rev-parse --verify --quiet 'refs/tags/$(PG18_RELEASE_TAG)' >/dev/null; then \
		printf 'ERROR: Tag %s already exists\n' '$(PG18_RELEASE_TAG)' >&2; \
		exit 1; \
	fi

validate-release-pg18vc:
	@printf '%s\n' '$(PG18VC_RELEASE_VERSION)' | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$$' || { \
		printf 'ERROR: VERSION must use vX.Y.Z format (received: %s)\n' '$(PG18VC_RELEASE_VERSION)' >&2; \
		exit 1; \
	}
	@if git rev-parse --verify --quiet 'refs/tags/$(PG18VC_RELEASE_TAG)' >/dev/null; then \
		printf 'ERROR: Tag %s already exists\n' '$(PG18VC_RELEASE_TAG)' >&2; \
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

validate-release-pg19basic:
	@printf '%s\n' '$(PG19BASIC_RELEASE_VERSION)' | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$$' || { \
		printf 'ERROR: VERSION must use vX.Y.Z format (received: %s)\n' '$(PG19BASIC_RELEASE_VERSION)' >&2; \
		exit 1; \
	}
	@if git rev-parse --verify --quiet 'refs/tags/$(PG19BASIC_RELEASE_TAG)' >/dev/null; then \
		printf 'ERROR: Tag %s already exists\n' '$(PG19BASIC_RELEASE_TAG)' >&2; \
		exit 1; \
	fi


release-pg17: validate-release-pg17
	@printf 'Creating release %s\n' '$(PG17_RELEASE_TAG)'
	git tag -a '$(PG17_RELEASE_TAG)' -m 'Release $(PG17_RELEASE_TAG)'
	git push origin '$(PG17_RELEASE_TAG)'
	@printf 'Released %s; the PG17 GitHub workflow will build image tag %s.\n' '$(PG17_RELEASE_TAG)' '$(PG17_RELEASE_VERSION)'

release-pg18: validate-release-pg18
	@printf 'Creating release %s\n' '$(PG18_RELEASE_TAG)'
	git tag -a '$(PG18_RELEASE_TAG)' -m 'Release $(PG18_RELEASE_TAG)'
	git push origin '$(PG18_RELEASE_TAG)'
	@printf 'Released %s; the PG18 GitHub workflow will build image tag %s.\n' '$(PG18_RELEASE_TAG)' '$(PG18_RELEASE_VERSION)'

release-pg18vc: validate-release-pg18vc
	@printf 'Creating release %s\n' '$(PG18VC_RELEASE_TAG)'
	git tag -a '$(PG18VC_RELEASE_TAG)' -m 'Release $(PG18VC_RELEASE_TAG)'
	git push origin '$(PG18VC_RELEASE_TAG)'
	@printf 'Released %s; the PG18 VectorChord GitHub workflow will build image tag %s.\n' '$(PG18VC_RELEASE_TAG)' '$(PG18VC_RELEASE_VERSION)'

release-pg19: validate-release-pg19
	@printf 'Creating release %s\n' '$(PG19_RELEASE_TAG)'
	git tag -a '$(PG19_RELEASE_TAG)' -m 'Release $(PG19_RELEASE_TAG)'
	git push origin '$(PG19_RELEASE_TAG)'
	@printf 'Released %s; the PG19 GitHub workflow will build image tag %s.\n' '$(PG19_RELEASE_TAG)' '$(PG19_RELEASE_VERSION)'

release-pg19basic: validate-release-pg19basic
	@printf 'Creating release %s\n' '$(PG19BASIC_RELEASE_TAG)'
	git tag -a '$(PG19BASIC_RELEASE_TAG)' -m 'Release $(PG19BASIC_RELEASE_TAG)'
	git push origin '$(PG19BASIC_RELEASE_TAG)'
	@printf 'Released %s; the PG19 Basic GitHub workflow will build image tag %s.\n' '$(PG19BASIC_RELEASE_TAG)' '$(PG19BASIC_RELEASE_VERSION)'
