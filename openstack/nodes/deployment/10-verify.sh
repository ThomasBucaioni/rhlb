#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -ne 0 ]] || { echo "Run as regular user." >&2; exit 1; }
source "$HOME/venvs/kolla/bin/activate"
kolla-ansible --version
ansible --version
test -f /etc/kolla/globals.yml
test -f /etc/kolla/passwords.yml
test -f "$HOME/multinode"
echo "Deployment host prerequisites present."
