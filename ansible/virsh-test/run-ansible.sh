#!/usr/bin/env bash
# Run the PostgreSQL role against installed virsh-test guests.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
INVENTORY="${INVENTORY:-$SCRIPT_DIR/inventory.yml}"
PRIVATE_KEY="${ANSIBLE_PRIVATE_KEY:-}"

command -v ansible-playbook >/dev/null || {
  printf 'ansible-playbook is required.\n' >&2
  exit 1
}

arguments=(-i "$INVENTORY" "$ANSIBLE_DIR/site.yml" --limit postgresql_linux)
if [[ -n "$PRIVATE_KEY" ]]; then
  arguments+=(--private-key "$PRIVATE_KEY")
fi

ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" ansible-playbook "${arguments[@]}" "$@"
