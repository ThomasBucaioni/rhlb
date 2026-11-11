#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT}/config/lab.conf"
[[ $EUID -ne 0 ]] || { echo "Run as regular user." >&2; exit 1; }
for item in "$CONTROLLER_IP" "$COMPUTE1_IP" "$COMPUTE2_IP" "$BLOCK1_IP"; do
  ping -c 1 -W 2 "$item" >/dev/null || { echo "No ping response from $item" >&2; exit 1; }
done
for target in "$CONTROLLER_IP" "$COMPUTE1_IP" "$COMPUTE2_IP" "$BLOCK1_IP"; do
  ssh -i "$SSH_KEY_ON_DEPLOYMENT" -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes "${SSH_USER}@${target}" 'sudo -n true' || {
      echo "SSH/passwordless sudo check failed for $target" >&2; exit 1;
    }
done
printf 'Deployment VM preflight passed.\n'
