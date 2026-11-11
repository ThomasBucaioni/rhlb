#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT}/config/lab.conf"
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }

ip link show "$IFACE_CONTROLLER_MANAGEMENT" >/dev/null
ip -o -4 addr show dev "$IFACE_CONTROLLER_MANAGEMENT" | grep -q "${CONTROLLER_IP}/" || {
  echo "${IFACE_CONTROLLER_MANAGEMENT} does not have ${CONTROLLER_IP}." >&2; exit 1;
}
ip link show "$IFACE_CONTROLLER_PROVIDER" >/dev/null
if ip -o -4 addr show dev "$IFACE_CONTROLLER_PROVIDER" | grep -q .; then
  echo "Provider interface $IFACE_CONTROLLER_PROVIDER has an IPv4 address; expected an unnumbered interface." >&2
  exit 1
fi
printf 'Controller preflight passed.\n'
