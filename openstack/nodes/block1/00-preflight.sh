#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT}/config/lab.conf"
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
ip link show "$IFACE_BLOCK1_MANAGEMENT" >/dev/null
ip -o -4 addr show dev "$IFACE_BLOCK1_MANAGEMENT" | grep -q "${BLOCK1_IP}/" || {
  echo "${IFACE_BLOCK1_MANAGEMENT} does not have ${BLOCK1_IP}." >&2; exit 1;
}
[[ -b "$CINDER_DISK" ]] || { echo "Cinder disk not found: $CINDER_DISK" >&2; exit 1; }
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$CINDER_DISK"
printf 'block1 preflight passed. Inspect disk signatures before storage initialization.\n'
