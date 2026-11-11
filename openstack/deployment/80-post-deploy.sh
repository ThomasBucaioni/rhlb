#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"
source "${KOLLA_VENV}/bin/activate"

kolla-ansible post-deploy
python -m pip install python-openstackclient
