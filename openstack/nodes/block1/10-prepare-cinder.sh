#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT}/config/lab.conf"

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }

if [[ "${1:-}" != "--confirm-disk" || "${2:-}" != "$CINDER_DISK" ]]; then
    echo "Refusing to initialize storage without explicit confirmation." >&2
    echo "Usage: sudo $0 --confirm-disk ${CINDER_DISK}" >&2
    exit 2
fi

[[ -b "$CINDER_DISK" ]] || { echo "Block device not found: $CINDER_DISK" >&2; exit 1; }

dnf install -y lvm2

if ! vgs "$CINDER_VOLUME_GROUP" >/dev/null 2>&1; then
    if pvs "$CINDER_DISK" >/dev/null 2>&1; then
        echo "$CINDER_DISK is already an LVM PV but VG $CINDER_VOLUME_GROUP does not exist." >&2
        echo "Inspect with pvs/vgs; refusing to alter it." >&2
        exit 1
    fi

    if wipefs -n "$CINDER_DISK" 2>/dev/null | awk 'NR > 1 { found=1 } END { exit !found }'; then
        echo "$CINDER_DISK contains filesystem/partition signatures. Refusing to wipe it." >&2
        wipefs -n "$CINDER_DISK" || true
        exit 1
    fi

    pvcreate "$CINDER_DISK"
    vgcreate "$CINDER_VOLUME_GROUP" "$CINDER_DISK"
else
    echo "VG $CINDER_VOLUME_GROUP already exists; leaving its PV layout unchanged."
fi

if ! lvs "${CINDER_VOLUME_GROUP}/${CINDER_THINPOOL}" >/dev/null 2>&1; then
    lvcreate -l "${CINDER_THINPOOL_PERCENT}%VG" \
      -T "${CINDER_VOLUME_GROUP}/${CINDER_THINPOOL}"
else
    echo "Thin pool ${CINDER_VOLUME_GROUP}/${CINDER_THINPOOL} already exists."
fi

modprobe target_core_mod
modprobe iscsi_target_mod

cat > /etc/modules-load.d/cinder-lio.conf <<'EOF'
target_core_mod
iscsi_target_mod
EOF

systemctl restart systemd-modules-load.service

mkdir -p /sys/kernel/config
if ! grep -qE '^[[:space:]]*configfs[[:space:]]+/sys/kernel/config[[:space:]]+configfs([[:space:]]|$)' /etc/fstab; then
    echo 'configfs /sys/kernel/config configfs defaults 0 0' >> /etc/fstab
fi

mountpoint -q /sys/kernel/config || mount /sys/kernel/config

echo
echo "Cinder storage preparation complete:"
pvs
vgs
lvs -a -o lv_name,lv_size,lv_attr,data_percent,metadata_percent
lsmod | grep -E 'target_core_mod|iscsi_target_mod'
findmnt /sys/kernel/config
