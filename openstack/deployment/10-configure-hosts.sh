#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"

SSH_OPTS=(-i "$SSH_KEY_ON_DEPLOYMENT" -o StrictHostKeyChecking=accept-new)

HOST_LINES=$(cat <<EOF
${DEPLOYMENT_IP} ${DEPLOYMENT_FQDN} ${DEPLOYMENT_NAME}
${CONTROLLER_IP} ${CONTROLLER_FQDN} ${CONTROLLER_NAME}
${COMPUTE1_IP} ${COMPUTE1_FQDN} ${COMPUTE1_NAME}
${COMPUTE2_IP} ${COMPUTE2_FQDN} ${COMPUTE2_NAME}
${BLOCK1_IP} ${BLOCK1_FQDN} ${BLOCK1_NAME}
EOF
)

append_local() {
    if ! sudo grep -q '^# BEGIN KOLLA HOMELAB HOSTS$' /etc/hosts; then
        {
            echo "# BEGIN KOLLA HOMELAB HOSTS"
            printf '%s\n' "$HOST_LINES"
            echo "# END KOLLA HOMELAB HOSTS"
        } | sudo tee -a /etc/hosts >/dev/null
    fi
}

append_remote() {
    local ip="$1"
    local payload
    payload="$(printf '%s\n' "$HOST_LINES" | sed "s/'/'\\\\''/g")"
    ssh "${SSH_OPTS[@]}" "${SSH_USER}@${ip}" \
      "sudo sh -c 'grep -q \"^# BEGIN KOLLA HOMELAB HOSTS\\$\" /etc/hosts || { printf \"%s\\\\n\" \"$payload\" >> /etc/hosts; }'"
}

append_local
for ip in "$CONTROLLER_IP" "$COMPUTE1_IP" "$COMPUTE2_IP" "$BLOCK1_IP"; do
    echo "Updating /etc/hosts on $ip"
    append_remote "$ip"
done

echo "Host mappings configured."
