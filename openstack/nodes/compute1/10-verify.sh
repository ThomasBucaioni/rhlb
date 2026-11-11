#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
ip -br link
ip -br address
systemctl is-active docker
docker ps
egrep -m1 -o 'vmx|svm' /proc/cpuinfo || true
