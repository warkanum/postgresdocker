#!/usr/bin/env bash
# Create test VMs without altering any existing libvirt resource. The ISOs boot
# into their native installers; see README.md for the one-time guest setup.
set -euo pipefail

LIBVIRT_URI="${LIBVIRT_URI:-qemu:///system}"
VIRSH=(virsh --connect "$LIBVIRT_URI")
VIRT_INSTALL=(virt-install --connect "$LIBVIRT_URI")
NETWORK_NAME="${NETWORK_NAME:-pgza-test}"
NETWORK_CIDR="${NETWORK_CIDR:-192.168.251}"
# Prefer a dedicated pgza-test pool, then separate images/isos pools. A generic
# active pool is only used as a fallback for hosts without the dedicated pools.
TEST_STORAGE_POOL="${TEST_STORAGE_POOL:-pgza-test}"
IMAGE_STORAGE_POOL="${IMAGE_STORAGE_POOL:-images}"
ISO_STORAGE_POOL="${ISO_STORAGE_POOL:-isos}"
STORAGE_POOL="${STORAGE_POOL:-}"
# These are derived from the selected pool targets unless explicitly overridden.
ISO_DIR="${ISO_DIR:-}"
IMAGE_DIR="${IMAGE_DIR:-}"
DISK_SIZE_GIB="${DISK_SIZE_GIB:-15}"
MEMORY_MIB="${MEMORY_MIB:-4096}"
VCPUS="${VCPUS:-4}"

declare -A ISO_URLS=(
  [arch]="${ARCH_ISO_URL:-https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso}"
  [alma]="${ALMA_ISO_URL:-https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-minimal.iso}"
  [void]="${VOID_ISO_URL:-https://repo-default.voidlinux.org/live/current/void-live-x86_64-20250202-base.iso}"
  [ubuntu]="${UBUNTU_ISO_URL:-https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso}"
)
declare -A ISO_FILES=(
  [arch]="archlinux-x86_64.iso"
  [alma]="AlmaLinux-9-latest-x86_64-minimal.iso"
  [void]="void-live-x86_64-base.iso"
  [ubuntu]="ubuntu-24.04.4-live-server-amd64.iso"
)
declare -A VM_NAMES=([arch]=pgza-arch [alma]=pgza-alma [void]=pgza-void [ubuntu]=pgza-ubuntu)
declare -A VM_MACS=(
  [arch]=52:54:00:25:18:11
  [alma]=52:54:00:25:18:12
  [void]=52:54:00:25:18:13
  [ubuntu]=52:54:00:25:18:14
)
declare -A VM_IPS=([arch]=.11 [alma]=.12 [void]=.13 [ubuntu]=.14)

usage() {
  printf 'Usage: %s [all|arch|alma|void|ubuntu]...\n' "$0"
}

require_commands() {
  local command
  for command in virsh virt-install qemu-img curl; do
    command -v "$command" >/dev/null || {
      printf 'Missing required command: %s\n' "$command" >&2
      exit 1
    }
  done
}

require_libvirt_connection() {
  "${VIRSH[@]}" uri >/dev/null 2>&1 || {
    printf 'Cannot connect to libvirt at %s. Install and start libvirt, or set LIBVIRT_URI.\n' "$LIBVIRT_URI" >&2
    exit 1
  }
}

pool_target() {
  local pool="$1"
  local pool_xml
  pool_xml="$("${VIRSH[@]}" pool-dumpxml "$pool")"
  awk -F '[<>]' '
    /<target>/ { in_target = 1; next }
    in_target && /<path>/ { print $3; exit }
    /<\/target>/ { in_target = 0 }
  ' <<<"$pool_xml"
}

pool_is_active() {
  local pool="$1"
  local pool_info
  pool_info="$("${VIRSH[@]}" pool-info "$pool" 2>/dev/null)" || return 1
  [[ "$pool_info" =~ State:[[:space:]]+running ]]
}

discover_fallback_pool() {
  local pool pools
  if [[ -n "$STORAGE_POOL" ]]; then
    printf '%s\n' "$STORAGE_POOL"
    return
  fi

  pools="$("${VIRSH[@]}" pool-list --name)"
  while IFS= read -r pool; do
    [[ -z "$pool" || "$pool" == "$IMAGE_STORAGE_POOL" || "$pool" == "$ISO_STORAGE_POOL" ]] && continue
    printf '%s\n' "$pool"
    return
  done <<<"$pools"
}

select_storage_directories() {
  local fallback_pool pool_target_path

  if [[ -z "$ISO_DIR" || -z "$IMAGE_DIR" ]] && pool_is_active "$TEST_STORAGE_POOL"; then
    pool_target_path="$(pool_target "$TEST_STORAGE_POOL")"
    ISO_DIR="${ISO_DIR:-$pool_target_path/isos}"
    IMAGE_DIR="${IMAGE_DIR:-$pool_target_path/images}"
    return
  fi

  if [[ -z "$IMAGE_DIR" ]] && pool_is_active "$IMAGE_STORAGE_POOL"; then
    IMAGE_DIR="$(pool_target "$IMAGE_STORAGE_POOL")"
  fi
  if [[ -z "$ISO_DIR" ]] && pool_is_active "$ISO_STORAGE_POOL"; then
    ISO_DIR="$(pool_target "$ISO_STORAGE_POOL")"
  fi

  if [[ -z "$ISO_DIR" || -z "$IMAGE_DIR" ]]; then
    fallback_pool="$(discover_fallback_pool)"
    [[ -n "$fallback_pool" ]] && pool_is_active "$fallback_pool" || {
      printf 'No suitable active libvirt storage pool was found. Start pgza-test, images/isos, or set ISO_DIR and IMAGE_DIR.\n' >&2
      exit 1
    }
    pool_target_path="$(pool_target "$fallback_pool")"
    ISO_DIR="${ISO_DIR:-$pool_target_path/pgza-test/isos}"
    IMAGE_DIR="${IMAGE_DIR:-$pool_target_path/pgza-test/images}"
  fi
}

ensure_network() {
  local network_info network_xml
  if ! "${VIRSH[@]}" net-info "$NETWORK_NAME" >/dev/null 2>&1; then
    network_xml="$(mktemp)"
    cat >"$network_xml" <<EOF
<network>
  <name>${NETWORK_NAME}</name>
  <forward mode='nat'/>
  <bridge name='virbr-pgza' stp='on' delay='0'/>
  <domain name='pgza.test'/>
  <ip address='${NETWORK_CIDR}.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='${NETWORK_CIDR}.100' end='${NETWORK_CIDR}.200'/>
      <host mac='${VM_MACS[arch]}' name='${VM_NAMES[arch]}' ip='${NETWORK_CIDR}${VM_IPS[arch]}'/>
      <host mac='${VM_MACS[alma]}' name='${VM_NAMES[alma]}' ip='${NETWORK_CIDR}${VM_IPS[alma]}'/>
      <host mac='${VM_MACS[void]}' name='${VM_NAMES[void]}' ip='${NETWORK_CIDR}${VM_IPS[void]}'/>
      <host mac='${VM_MACS[ubuntu]}' name='${VM_NAMES[ubuntu]}' ip='${NETWORK_CIDR}${VM_IPS[ubuntu]}'/>
    </dhcp>
  </ip>
</network>
EOF
    "${VIRSH[@]}" net-define "$network_xml"
    rm -f "$network_xml"
  fi

  "${VIRSH[@]}" net-autostart "$NETWORK_NAME" >/dev/null
  network_info="$("${VIRSH[@]}" net-info "$NETWORK_NAME")"
  if [[ ! "$network_info" =~ Active:[[:space:]]+yes ]]; then
    "${VIRSH[@]}" net-start "$NETWORK_NAME"
  fi
}

download_iso() {
  local distro="$1"
  local destination="$ISO_DIR/${ISO_FILES[$distro]}"
  if [[ -f "$destination" ]]; then
    printf 'ISO exists, skipping: %s\n' "$destination"
    return
  fi

  printf 'Downloading %s ISO from %s\n' "$distro" "${ISO_URLS[$distro]}"
  curl --fail --location --retry 3 --continue-at - \
    --output "${destination}.part" "${ISO_URLS[$distro]}"
  mv "${destination}.part" "$destination"
}

create_vm() {
  local distro="$1"
  local name="${VM_NAMES[$distro]}"
  local disk="$IMAGE_DIR/${name}.qcow2"
  local iso="$ISO_DIR/${ISO_FILES[$distro]}"

  if "${VIRSH[@]}" dominfo "$name" >/dev/null 2>&1; then
    printf 'VM exists, skipping: %s\n' "$name"
    return
  fi

  if [[ ! -f "$disk" ]]; then
    qemu-img create -f qcow2 "$disk" "${DISK_SIZE_GIB}G"
  fi

  "${VIRT_INSTALL[@]}" \
    --name "$name" \
    --memory "$MEMORY_MIB" \
    --vcpus "$VCPUS" \
    --disk "path=$disk,format=qcow2,bus=virtio" \
    --network "network=$NETWORK_NAME,mac=${VM_MACS[$distro]},model=virtio" \
    --cdrom "$iso" \
    --os-variant generic \
    --graphics none \
    --console pty,target.type=serial \
    --noautoconsole \
    --wait 0
  printf 'VM started from installer ISO: %s\n' "$name"
}

main() {
  local targets=("$@")
  if [[ ${#targets[@]} -eq 0 || "${targets[0]}" == all ]]; then
    targets=(arch alma void ubuntu)
  fi

  require_commands
  require_libvirt_connection
  select_storage_directories
  mkdir -p "$ISO_DIR" "$IMAGE_DIR"
  ensure_network

  local distro
  for distro in "${targets[@]}"; do
    [[ -n "${VM_NAMES[$distro]:-}" ]] || { usage >&2; exit 2; }
    download_iso "$distro"
    create_vm "$distro"
  done
}

main "$@"
