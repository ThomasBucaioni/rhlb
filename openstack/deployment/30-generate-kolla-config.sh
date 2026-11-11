#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"

[[ $EUID -ne 0 ]] || { echo "Run as regular user." >&2; exit 1; }
[[ -x "${KOLLA_VENV}/bin/kolla-ansible" ]] || {
    echo "Kolla-Ansible is not installed. Run 20-install-kolla.sh first." >&2
    exit 1
}

# shellcheck disable=SC1090
source "${KOLLA_VENV}/bin/activate"

SAMPLE="${KOLLA_VENV}/share/kolla-ansible/ansible/inventory/multinode"
[[ -f "$SAMPLE" ]] || { echo "Missing sample inventory: $SAMPLE" >&2; exit 1; }

if [[ -f "$KOLLA_INVENTORY" ]]; then
    cp -a "$KOLLA_INVENTORY" "${KOLLA_INVENTORY}.backup.$(date +%Y%m%d%H%M%S)"
fi
cp "$SAMPLE" "$KOLLA_INVENTORY"

export SSH_USER SSH_KEY_ON_DEPLOYMENT
export CONTROLLER_FQDN CONTROLLER_IP COMPUTE1_FQDN COMPUTE1_IP
export COMPUTE2_FQDN COMPUTE2_IP BLOCK1_FQDN BLOCK1_IP
export IFACE_CONTROLLER_MANAGEMENT IFACE_CONTROLLER_PROVIDER
export IFACE_COMPUTE1_MANAGEMENT IFACE_COMPUTE2_MANAGEMENT IFACE_BLOCK1_MANAGEMENT

python3 - "$KOLLA_INVENTORY" "$HOME/host_vars" <<'PY'
import os
import re
import sys
from pathlib import Path

inventory = Path(sys.argv[1])
host_vars = Path(sys.argv[2])
text = inventory.read_text().splitlines()

def host_line(fqdn, address):
    return (
        f"{fqdn} ansible_host={address} "
        f"ansible_user={os.environ['SSH_USER']} "
        f"ansible_become=True "
        f"ansible_ssh_private_key_file={os.environ['SSH_KEY_ON_DEPLOYMENT']}"
    )

groups = {
    "control": [host_line(os.environ["CONTROLLER_FQDN"], os.environ["CONTROLLER_IP"])],
    "network": [host_line(os.environ["CONTROLLER_FQDN"], os.environ["CONTROLLER_IP"])],
    "compute": [
        host_line(os.environ["COMPUTE1_FQDN"], os.environ["COMPUTE1_IP"]),
        host_line(os.environ["COMPUTE2_FQDN"], os.environ["COMPUTE2_IP"]),
    ],
    "storage": [host_line(os.environ["BLOCK1_FQDN"], os.environ["BLOCK1_IP"])],
    "monitoring": [],
    "deployment": ["localhost ansible_connection=local"],
}

out = []
current = None
seen = set()

for line in text:
    match = re.match(r"^\s*\[([^\]]+)\]\s*$", line)
    if match:
        current = match.group(1)
        out.append(line)
        if current in groups:
            if current in seen:
                raise SystemExit(f"Duplicate inventory group: {current}")
            seen.add(current)
            out.extend(groups[current])
        continue

    if current in groups:
        # Remove active example hosts; preserve comments and blank lines.
        if not line.strip() or line.lstrip().startswith("#"):
            out.append(line)
        continue

    out.append(line)

missing = set(groups) - seen
if missing:
    raise SystemExit("Expected groups missing from Kolla sample inventory: " + ", ".join(sorted(missing)))

inventory.write_text("\n".join(out) + "\n")

host_vars.mkdir(parents=True, exist_ok=True)

vars_by_host = {
    os.environ["CONTROLLER_FQDN"]: {
        "network_interface": os.environ["IFACE_CONTROLLER_MANAGEMENT"],
        "neutron_external_interface": os.environ["IFACE_CONTROLLER_PROVIDER"],
    },
    os.environ["COMPUTE1_FQDN"]: {
        "network_interface": os.environ["IFACE_COMPUTE1_MANAGEMENT"],
    },
    os.environ["COMPUTE2_FQDN"]: {
        "network_interface": os.environ["IFACE_COMPUTE2_MANAGEMENT"],
    },
    os.environ["BLOCK1_FQDN"]: {
        "network_interface": os.environ["IFACE_BLOCK1_MANAGEMENT"],
    },
}

for host, values in vars_by_host.items():
    path = host_vars / host
    with path.open("w") as f:
        f.write("---\n")
        for key, value in values.items():
            f.write(f'{key}: "{value}"\n')
PY

cat > "${KOLLA_CONFIG_DIR}/globals.yml" <<EOF
---
kolla_base_distro: "${KOLLA_BASE_DISTRO}"
openstack_release: "${OPENSTACK_RELEASE}"

kolla_internal_vip_address: "${KOLLA_INTERNAL_VIP}"

neutron_plugin_agent: "openvswitch"
enable_neutron_provider_networks: "yes"

enable_horizon: "yes"
enable_heat: "yes"

enable_cinder: "yes"
enable_cinder_backup: "no"
enable_cinder_backend_iscsi: "no"
enable_cinder_backend_lvm: true
cinder_volume_group: "${CINDER_VOLUME_GROUP}"

cinder_volume_extra_volumes:
  - "/sys/kernel/config:/sys/kernel/config"
EOF

chmod 0600 "${KOLLA_CONFIG_DIR}/passwords.yml"
echo "Generated:"
echo "  $KOLLA_INVENTORY"
echo "  $HOME/host_vars/"
echo "  ${KOLLA_CONFIG_DIR}/globals.yml"
echo
echo "Review the generated inventory and host_vars before deployment."
