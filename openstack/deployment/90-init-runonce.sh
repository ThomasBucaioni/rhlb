#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"
source "${KOLLA_VENV}/bin/activate"

[[ -f "${KOLLA_CONFIG_DIR}/admin-openrc.sh" ]] || {
    echo "Missing admin-openrc.sh. Run 80-post-deploy.sh first." >&2
    exit 1
}

# shellcheck disable=SC1090
source "${KOLLA_CONFIG_DIR}/admin-openrc.sh"

if openstack network show demo-net >/dev/null 2>&1 ||
   openstack network show public1 >/dev/null 2>&1; then
    echo "demo-net or public1 already exists. Refusing to rerun init-runonce." >&2
    exit 1
fi

export DEMO_NET_CIDR
export DEMO_NET_GATEWAY
export DEMO_NET_DNS
export EXT_NET_CIDR
export EXT_NET_GATEWAY
export EXT_NET_RANGE="start=${EXT_NET_RANGE_START},end=${EXT_NET_RANGE_END}"
export ENABLE_EXT_NET=1

INIT_RUNONCE="${KOLLA_VENV}/share/kolla-ansible/init-runonce"
[[ -x "$INIT_RUNONCE" ]] || { echo "Missing init-runonce: $INIT_RUNONCE" >&2; exit 1; }

echo "Using init-runonce overrides:"
env | grep -E '^(DEMO_NET_|EXT_NET_|ENABLE_EXT_NET=)' | sort

"$INIT_RUNONCE"
