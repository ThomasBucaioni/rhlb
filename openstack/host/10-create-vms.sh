#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/config/lab.conf"

[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

create_vm() {
    local name="$1" vcpu="$2" ram="$3" root_gib="$4" data_gib="$5"
    local ks_file="$6" networks="$7"
    local root_disk="${VM_DISK_DIR}/${name}-root.qcow2"
    local data_disk="${VM_DISK_DIR}/${name}-data.qcow2"
    local ks_path="${KICKSTART_DIR}/${ks_file}"
    local -a args netargs
    local network

    if virsh -c "$LIBVIRT_URI" dominfo "$name" >/dev/null 2>&1; then
        echo "SKIP: domain $name already exists."
        return
    fi

    [[ -r "$ks_path" ]] || { echo "Missing Kickstart: $ks_path" >&2; exit 1; }

    if [[ -e "$root_disk" ]]; then
        echo "ERROR: $root_disk exists but domain $name does not. Refusing to overwrite." >&2
        exit 1
    fi
    if (( data_gib > 0 )) && [[ -e "$data_disk" ]]; then
        echo "ERROR: $data_disk exists but domain $name does not. Refusing to overwrite." >&2
        exit 1
    fi

    args=(
      --connect "$LIBVIRT_URI"
      --name "$name"
      --virt-type kvm
      --machine q35
      --memory "$ram"
      --vcpus "$vcpu"
      --cpu host-passthrough
      --os-variant "$OS_VARIANT"
      --disk "path=${root_disk},size=${root_gib},format=qcow2,bus=virtio"
      --graphics none
      --console pty,target_type=serial
      --location "$RHEL_INSTALL_SOURCE"
      --initrd-inject "$ks_path"
      --extra-args "inst.ks=file:/$(basename "$ks_path") inst.text console=ttyS0,115200n8"
      --noautoconsole
      --wait 0
    )

    if (( data_gib > 0 )); then
        args+=(--disk "path=${data_disk},size=${data_gib},format=qcow2,bus=virtio")
    fi

    IFS=',' read -r -a netargs <<< "$networks"
    for network in "${netargs[@]}"; do
        case "$network" in
          nat)
            args+=(--network "network=${NAT_NETWORK},model=virtio")
            ;;
          management)
            args+=(--network "bridge=${MGMT_BRIDGE},model=virtio")
            ;;
          provider)
            args+=(--network "bridge=${PROVIDER_BRIDGE},model=virtio")
            ;;
          *)
            echo "Unknown network '$network' for VM $name" >&2
            exit 1
            ;;
        esac
    done

    echo "Creating $name: ${vcpu} vCPU, ${ram} MiB RAM, ${root_gib} GiB root, ${data_gib} GiB data"
    virt-install "${args[@]}"
    virsh -c "$LIBVIRT_URI" autostart "$name"
}

"${ROOT}/host/00-preflight.sh"

create_vm "$DEPLOYMENT_NAME" "$VM_DEPLOYMENT_VCPU" "$VM_DEPLOYMENT_RAM_MIB" \
  "$VM_DEPLOYMENT_ROOT_GIB" "$VM_DEPLOYMENT_DATA_GIB" "$VM_DEPLOYMENT_KS" "$VM_DEPLOYMENT_NETWORKS"

create_vm "$CONTROLLER_NAME" "$VM_CONTROLLER_VCPU" "$VM_CONTROLLER_RAM_MIB" \
  "$VM_CONTROLLER_ROOT_GIB" "$VM_CONTROLLER_DATA_GIB" "$VM_CONTROLLER_KS" "$VM_CONTROLLER_NETWORKS"

create_vm "$COMPUTE1_NAME" "$VM_COMPUTE1_VCPU" "$VM_COMPUTE1_RAM_MIB" \
  "$VM_COMPUTE1_ROOT_GIB" "$VM_COMPUTE1_DATA_GIB" "$VM_COMPUTE1_KS" "$VM_COMPUTE1_NETWORKS"

create_vm "$COMPUTE2_NAME" "$VM_COMPUTE2_VCPU" "$VM_COMPUTE2_RAM_MIB" \
  "$VM_COMPUTE2_ROOT_GIB" "$VM_COMPUTE2_DATA_GIB" "$VM_COMPUTE2_KS" "$VM_COMPUTE2_NETWORKS"

create_vm "$BLOCK1_NAME" "$VM_BLOCK1_VCPU" "$VM_BLOCK1_RAM_MIB" \
  "$VM_BLOCK1_ROOT_GIB" "$VM_BLOCK1_DATA_GIB" "$VM_BLOCK1_KS" "$VM_BLOCK1_NETWORKS"

echo "VM creation commands submitted. Check installations with: virsh list --all"
