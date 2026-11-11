#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"

SSH_OPTS=(-i "$SSH_KEY_ON_DEPLOYMENT" -o StrictHostKeyChecking=accept-new)
BUNDLE_NAME="kolla-homelab-automation"

copy_node() {
    local node="$1" ip="$2"
    local remote_base="${SSH_USER}@${ip}:~/${BUNDLE_NAME}"
    ssh "${SSH_OPTS[@]}" "${SSH_USER}@${ip}" \
      "mkdir -p ~/${BUNDLE_NAME}/config ~/${BUNDLE_NAME}/nodes/${node}"
    scp "${SSH_OPTS[@]}" "${ROOT}/config/lab.conf" \
      "${remote_base}/config/lab.conf"
    scp "${SSH_OPTS[@]}" "${ROOT}/nodes/${node}/"*.sh \
      "${remote_base}/nodes/${node}/"
    ssh "${SSH_OPTS[@]}" "${SSH_USER}@${ip}" \
      "chmod 0755 ~/${BUNDLE_NAME}/nodes/${node}/*.sh"
}

copy_node controller "$CONTROLLER_IP"
copy_node compute1 "$COMPUTE1_IP"
copy_node compute2 "$COMPUTE2_IP"
copy_node block1 "$BLOCK1_IP"

echo "Role scripts and lab.conf distributed to all four OpenStack nodes."
