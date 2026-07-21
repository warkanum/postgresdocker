#!/usr/bin/env bash
# Reinstall the test guests unattended. This intentionally replaces VM disks.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIBVIRT_URI="${LIBVIRT_URI:-qemu:///system}"
VIRT_INSTALL=(virt-install --connect "$LIBVIRT_URI")
ISO_DIR="${ISO_DIR:-/home/warkanum/vm/storage/pgza-test/isos}"
BOOTSTRAP_PASSWORD="${BOOTSTRAP_PASSWORD:-}"

declare -A VM_NAMES=([arch]=pgza-arch [alma]=pgza-alma [void]=pgza-void [ubuntu]=pgza-ubuntu)
declare -A ISO_FILES=(
  [arch]=archlinux-x86_64.iso
  [alma]=AlmaLinux-9-latest-x86_64-minimal.iso
  [void]=void-live-x86_64-base.iso
  [ubuntu]=ubuntu-24.04.4-live-server-amd64.iso
)
declare -A OS_VARIANTS=([arch]=archlinux [alma]=almalinux9 [void]=generic [ubuntu]=ubuntu24.04)
targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  targets=(arch alma void ubuntu)
fi

[[ "${CONFIRM_REINSTALL:-}" == 1 ]] || {
  printf 'Set CONFIRM_REINSTALL=1 to replace the existing test guest installations.\n' >&2
  exit 2
}
[[ -n "$BOOTSTRAP_PASSWORD" ]] || { printf 'Set BOOTSTRAP_PASSWORD for the temporary ansible account.\n' >&2; exit 1; }
password_file="$(mktemp)"
trap 'rm -f "$password_file"' EXIT
chmod 600 "$password_file"
printf '%s\n' "$BOOTSTRAP_PASSWORD" >"$password_file"

for distro in "${targets[@]}"; do
  [[ -n "${VM_NAMES[$distro]:-}" ]] || { printf 'Unknown VM: %s\n' "$distro" >&2; exit 2; }
  iso="$ISO_DIR/${ISO_FILES[$distro]}"
  [[ -f "$iso" ]] || { printf 'ISO not found: %s\n' "$iso" >&2; exit 1; }

  case "$distro" in
    alma|ubuntu)
      "${VIRT_INSTALL[@]}" --reinstall "${VM_NAMES[$distro]}" \
        --cdrom "$iso" \
        --os-variant "${OS_VARIANTS[$distro]}" \
        --unattended "user-login=ansible,admin-password-file=$password_file,user-password-file=$password_file" \
        --wait -1
      ;;
    arch|void)
      printf '%s native installation is not wired into bootstrap-vms.sh yet.\n' "$distro" >&2
      exit 1
      ;;
  esac
done
