#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT}/config/lab.conf"
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
ip link show "$IFACE_COMPUTE1_MANAGEMENT" >/dev/null
ip -o -4 addr show dev "$IFACE_COMPUTE1_MANAGEMENT" | grep -q "${COMPUTE1_IP}/" || {
  echo "${IFACE_COMPUTE1_MANAGEMENT} does not have ${COMPUTE1_IP}." >&2; exit 1;
}
grep -Eqw 'vmx|svm' /proc/cpuinfo || {
  echo "CPU virtualization extensions are not exposed to this VM." >&2; exit 1;
}
printf 'compute1 preflight passed.\n'
