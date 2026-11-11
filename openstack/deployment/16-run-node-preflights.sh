#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"
SSH_OPTS=(-i "$SSH_KEY_ON_DEPLOYMENT" -o StrictHostKeyChecking=accept-new)

run_remote() {
  local node="$1" ip="$2"
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${ip}" \
    "sudo ~/kolla-homelab-automation/nodes/${node}/00-preflight.sh"
}

run_remote controller "$CONTROLLER_IP"
run_remote compute1 "$COMPUTE1_IP"
run_remote compute2 "$COMPUTE2_IP"
run_remote block1 "$BLOCK1_IP"

echo "All target-node preflights passed."
