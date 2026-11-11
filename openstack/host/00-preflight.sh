#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../config/lab.conf.example
source "${ROOT}/config/lab.conf"

die() { echo "ERROR: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

[[ $EUID -eq 0 ]] || die "Run as root."
need virsh
need virt-install
need qemu-img
need ip

virsh -c "$LIBVIRT_URI" uri >/dev/null
virsh -c "$LIBVIRT_URI" pool-info "$STORAGE_POOL" >/dev/null 2>&1 ||
  die "Libvirt storage pool is unavailable: $STORAGE_POOL"

[[ -r "$RHEL_INSTALL_SOURCE" ]] || die "Cannot read RHEL_INSTALL_SOURCE: $RHEL_INSTALL_SOURCE"
[[ -d "$KICKSTART_DIR" ]] || die "KICKSTART_DIR does not exist: $KICKSTART_DIR"
[[ -d "$VM_DISK_DIR" ]] || die "VM_DISK_DIR does not exist: $VM_DISK_DIR"

virsh -c "$LIBVIRT_URI" net-info "$NAT_NETWORK" >/dev/null 2>&1 ||
  die "Libvirt network not found: $NAT_NETWORK"

ip link show "$MGMT_BRIDGE" >/dev/null 2>&1 ||
  die "Management bridge not found: $MGMT_BRIDGE"

ip link show "$PROVIDER_BRIDGE" >/dev/null 2>&1 ||
  die "Provider bridge not found: $PROVIDER_BRIDGE"

for name in deployment controller compute1 compute2 block1; do
  var="VM_${name^^}_KS"
  ks="${!var}"
  [[ -r "${KICKSTART_DIR}/${ks}" ]] ||
    die "Missing Kickstart: ${KICKSTART_DIR}/${ks}"
done

echo "Preflight successful."
echo "Libvirt URI:       $LIBVIRT_URI"
echo "NAT network:       $NAT_NETWORK"
echo "Management bridge: $MGMT_BRIDGE"
echo "Provider bridge:   $PROVIDER_BRIDGE"
echo "Install source:    $RHEL_INSTALL_SOURCE"
