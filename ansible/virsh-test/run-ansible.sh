#!/usr/bin/env bash
# Run the PostgreSQL role against installed virsh-test guests.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
INVENTORY="${INVENTORY:-$SCRIPT_DIR/inventory.yml}"
PRIVATE_KEY="${ANSIBLE_PRIVATE_KEY:-}"
ANSIBLE_PASSWORD="${ANSIBLE_PASSWORD:-}"
CONNECTION_TIMEOUT="${CONNECTION_TIMEOUT:-15}"

command -v ansible-playbook >/dev/null || {
  printf 'ansible-playbook is required.\n' >&2
  exit 1
}
command -v ansible >/dev/null || {
  printf 'ansible is required for the guest readiness check.\n' >&2
  exit 1
}

arguments=(-i "$INVENTORY" "$ANSIBLE_DIR/site.yml" --limit postgresql_linux)
connection_arguments=(-i "$INVENTORY" postgresql_linux -m ansible.builtin.wait_for_connection -a "timeout=$CONNECTION_TIMEOUT")
if [[ -n "$PRIVATE_KEY" ]]; then
  arguments+=(--private-key "$PRIVATE_KEY")
  connection_arguments+=(--private-key "$PRIVATE_KEY")
fi
if [[ -n "$ANSIBLE_PASSWORD" ]]; then
  arguments+=(-e "ansible_password=$ANSIBLE_PASSWORD" -e "ansible_become_password=$ANSIBLE_PASSWORD")
  connection_arguments+=(-e "ansible_password=$ANSIBLE_PASSWORD")
fi

# Test VMs are intentionally recreated often, so their SSH host keys are not
# persisted. Do not use this setting for non-disposable infrastructure.
if ! ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" ANSIBLE_HOST_KEY_CHECKING=False ansible "${connection_arguments[@]}"; then
  printf '%s\n' 'One or more guests are not ready for Ansible.' >&2
  printf '%s\n' 'Complete the ISO installation, enable sshd, create the ansible user with your SSH key and passwordless sudo, eject the ISO, then reboot the guest.' >&2
  exit 1
fi

ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook "${arguments[@]}" "$@"
