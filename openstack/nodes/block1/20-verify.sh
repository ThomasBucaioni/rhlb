#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
echo "LVM:"
pvs
vgs
lvs -a -o lv_name,lv_size,lv_attr,data_percent,metadata_percent
echo
echo "Kernel modules:"
lsmod | grep -E 'target_core_mod|iscsi_target_mod'
echo
echo "configfs:"
findmnt /sys/kernel/config
echo
echo "Cinder container:"
docker ps --filter name=cinder_volume
