#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
echo "Interfaces:"
ip -br link
ip -br address
echo
echo "Horizon:"
docker ps --filter name=horizon
echo
echo "Neutron/OVS containers:"
docker ps --format '{{.Names}}' | grep -E 'neutron|openvswitch|ovs' || true
