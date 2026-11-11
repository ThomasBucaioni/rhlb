#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"
source "${KOLLA_VENV}/bin/activate"
kolla-ansible deploy -i "$KOLLA_INVENTORY"
