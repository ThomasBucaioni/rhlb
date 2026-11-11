#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT}/config/lab.conf"
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
ip link show "$IFACE_COMPUTE2_MANAGEMENT" >/dev/null
ip -o -4 addr show dev "$IFACE_COMPUTE2_MANAGEMENT" | grep -q "${COMPUTE2_IP}/" || {
  echo "${IFACE_COMPUTE2_MANAGEMENT} does not have ${COMPUTE2_IP}." >&2; exit 1;
}
grep -Eqw 'vmx|svm' /proc/cpuinfo || {
  echo "CPU virtualization extensions are not exposed to this VM." >&2; exit 1;
}
printf 'compute2 preflight passed.\n'
