#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"
source "${KOLLA_VENV}/bin/activate"
source "${KOLLA_CONFIG_DIR}/admin-openrc.sh"

openstack service list
openstack endpoint list
openstack compute service list
openstack network agent list
openstack volume service list
openstack network list
openstack subnet list
openstack router list
openstack image list
openstack flavor list
openstack server list
openstack volume list
openstack floating ip list
