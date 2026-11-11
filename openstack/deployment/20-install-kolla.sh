#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"

[[ $EUID -ne 0 ]] || { echo "Run as the regular user, not root." >&2; exit 1; }

sudo dnf install -y \
  git python3 python3-devel python3-pip \
  gcc libffi-devel openssl-devel curl

mkdir -p "$(dirname "$KOLLA_VENV")"

if [[ ! -x "${KOLLA_VENV}/bin/python" ]]; then
    python3 -m venv "$KOLLA_VENV"
fi

# shellcheck disable=SC1090
source "${KOLLA_VENV}/bin/activate"

python -m pip install --upgrade pip
python -m pip install "git+https://opendev.org/openstack/kolla-ansible@${KOLLA_GIT_REF}"

sudo mkdir -p "$KOLLA_CONFIG_DIR"
sudo chown "$(id -u):$(id -g)" "$KOLLA_CONFIG_DIR"

EXAMPLES="${KOLLA_VENV}/share/kolla-ansible/etc_examples/kolla"
[[ -d "$EXAMPLES" ]] || { echo "Kolla example configuration not found: $EXAMPLES" >&2; exit 1; }

if [[ ! -f "${KOLLA_CONFIG_DIR}/globals.yml" ]]; then
    cp -a "${EXAMPLES}/." "$KOLLA_CONFIG_DIR/"
fi

if [[ ! -f "${KOLLA_CONFIG_DIR}/passwords.yml" ]]; then
    kolla-genpwd
fi

kolla-ansible install-deps

python -m pip freeze > "${HOME}/kolla-ansible-requirements.lock"

echo "Kolla-Ansible installed:"
kolla-ansible --version
echo "Virtualenv: $KOLLA_VENV"
echo "Configuration: $KOLLA_CONFIG_DIR"
