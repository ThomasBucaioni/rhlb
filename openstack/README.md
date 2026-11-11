# Kolla-Ansible OpenStack Homelab Automation Bundle

This bundle automates the five-VM RHEL 10 Kolla-Ansible lab:

- `deployment`
- `controller`
- `compute1`
- `compute2`
- `block1`

It is split into two execution locations:

1. **Home PC KVM/libvirt hypervisor:** validates the host and creates the five VMs.
2. **The VMs:** prepares the Cinder disk on `block1`, installs Kolla-Ansible on `deployment`, and deploys OpenStack to the four service nodes.

The bundle does not create or modify Kickstart files. It expects one Kickstart file per VM.

The deployment VM runs Kolla-Ansible centrally. Kolla-Ansible bootstraps and deploys containers to `controller`, `compute1`, `compute2` and `block1` over SSH; those four nodes do not run independent OpenStack installers. The per-node scripts handle preflight checks and the special Cinder host preparation.

## Important: review configuration before running

Copy the example configuration:

```bash
cp config/lab.conf.example config/lab.conf
vi config/lab.conf
```

At minimum, verify:

- `RHEL_INSTALL_SOURCE`
- `KICKSTART_DIR`
- `MGMT_BRIDGE` and `PROVIDER_BRIDGE`
- VM RAM, vCPU and disk sizes
- management IP addresses
- guest NIC names in the Kolla host variables
- Kickstart filenames and NIC ordering

The network attachments below are the starting topology represented by the lab notes:

- libvirt NAT network: `default`
- management bridge: `virbr4`
- provider bridge: `mybridge0`
- controller NIC order: provider, management, NAT
- other VM NIC order: management, NAT

The guest interface names are **not inferred from bridge names**. Check them inside each VM with `ip -br link` and make the interface values in `config/lab.conf` match the Kickstart configuration.

The VM resource values in the example configuration are editable starting values, not a record of the exact resource allocation of the already-running VMs.

## Kickstart files

By default, the host script expects:

```text
kickstarts/deployment.ks
kickstarts/controller.ks
kickstarts/compute1.ks
kickstarts/compute2.ks
kickstarts/block1.ks
```

Change the filenames in `config/lab.conf` if yours differ.

Each Kickstart must configure:

- the expected hostname/FQDN
- the `user` account
- SSH access for the deployment user (or permit `ssh-copy-id` afterwards)
- static management addresses
- the correct NIC for each network
- passwordless sudo for `user`
- RHEL 10 installation

The scripts attach NICs in the order defined by `VM_*_NETWORKS`. Keep that order consistent with the NIC selection in the Kickstart files.

## Phase A — create VMs on the home PC hypervisor

Install host-side tooling if it is not already installed:

```bash
sudo dnf install -y \
  qemu-kvm libvirt virt-install libvirt-client \
  qemu-img edk2-ovmf
sudo systemctl enable --now libvirtd
```

Unpack the bundle, edit `config/lab.conf`, place the Kickstart files in the configured directory, and run:

```bash
sudo ./host/00-preflight.sh
sudo ./host/10-create-vms.sh
```

The VM script is deliberately non-destructive:

- existing libvirt domains are skipped
- an existing disk file without a matching domain causes an error
- it never deletes a VM or disk
- it creates a separate Cinder data disk for `block1`

VM installation continues through the serial console. Use `virsh console VMNAME` if you need to inspect an installation.

## Phase B — prepare SSH access

After the VMs finish installing, ensure `user` can SSH from `deployment` to:

- `controller.ostacklab.local`
- `compute1.ostacklab.local`
- `compute2.ostacklab.local`
- `block1.ostacklab.local`

On `deployment`:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
ssh-copy-id user@10.0.0.11
ssh-copy-id user@10.0.0.21
ssh-copy-id user@10.0.0.22
ssh-copy-id user@10.0.0.41
```

If you use different IP addresses, use those from `config/lab.conf`.

Ensure `user` has passwordless sudo on every target.

After copying the bundle to `deployment` and editing `config/lab.conf`, run the deployment-host connectivity check:

```bash
./nodes/deployment/00-preflight.sh
```

Ensure `user` has passwordless sudo on every target.

Copy this bundle to `deployment`, for example:

```bash
scp -r kolla-homelab-automation user@10.0.0.10:~/
```

On `deployment`:

```bash
cd ~/kolla-homelab-automation
cp config/lab.conf.example config/lab.conf
vi config/lab.conf
```

Use the same configuration values as on the hypervisor. In particular, check the guest IPs, interface names, SSH key path and Cinder disk.

## Phase C — configure host name resolution

On `deployment`:

```bash
./deployment/10-configure-hosts.sh
./deployment/15-distribute-node-scripts.sh
./deployment/16-run-node-preflights.sh
```

This adds the lab's static name mappings to `/etc/hosts`, distributes each node's role scripts/configuration, and checks the management NIC/IP on each target. The compute checks also verify nested virtualization; the controller check verifies its unnumbered provider NIC. It uses SSH and passwordless sudo.

## Phase D — prepare Cinder storage

On `block1`, inspect the disk first:

```bash
lsblk -f
wipefs -n /dev/vdb
```

Then explicitly confirm the dedicated disk:

```bash
sudo ~/kolla-homelab-automation/nodes/block1/10-prepare-cinder.sh --confirm-disk /dev/vdb
```

The script creates:

- PV on `/dev/vdb`
- VG `cinder-volumes`
- thin pool `cinder-volumes-pool` using 95% of the VG
- persistent loading of `target_core_mod` and `iscsi_target_mod`
- persistent configfs mount at `/sys/kernel/config`

It refuses to initialize a disk containing existing signatures. If the VG already exists, it leaves the existing layout in place.

**Do not run this against a disk containing data you need.**

## Phase E — install Kolla-Ansible on deployment

On `deployment`, as `user`:

```bash
./deployment/20-install-kolla.sh
```

This creates `~/venvs/kolla`, installs Kolla-Ansible from the `stable/2026.1` branch, installs Ansible dependencies, initializes `/etc/kolla`, and generates passwords only if `passwords.yml` does not already exist.

## Phase F — generate Kolla configuration

On `deployment`:

```bash
./deployment/30-generate-kolla-config.sh
```

This generates:

- `~/multinode`
- `~/host_vars/*`
- `/etc/kolla/globals.yml`

It preserves the Kolla example inventory's service-group relationships and populates the `control`, `network`, `compute`, `storage`, and `deployment` groups.

The per-host network interface values are generated from `config/lab.conf`. This is intentional because the controller's provider NIC and management NIC may have different names from the other nodes.

## Phase G — deploy OpenStack

Run these scripts in order on `deployment`:

```bash
./deployment/40-test-ansible.sh
./deployment/50-bootstrap.sh
./deployment/60-prechecks.sh
./deployment/70-deploy.sh
./deployment/80-post-deploy.sh
```

`70-deploy.sh` performs the Kolla-Ansible deployment. It can take a considerable amount of time.

## Phase H — create the demo network and instance

On `deployment`:

```bash
./deployment/90-init-runonce.sh
```

The script uses the exact `init-runonce` variable names:

- `DEMO_NET_CIDR`
- `DEMO_NET_GATEWAY`
- `DEMO_NET_DNS`
- `EXT_NET_CIDR`
- `EXT_NET_GATEWAY`
- `EXT_NET_RANGE`

It refuses to run if `demo-net` or `public1` already exists, because the upstream `init-runonce` script is not idempotent.

The example network values reproduce the tested lab:

- tenant: `10.10.0.0/24`, gateway `10.10.0.1`
- external: `192.168.1.0/24`, gateway `192.168.1.254`
- external allocation pool: `192.168.1.210`–`192.168.1.220`
- DNS: `192.168.1.254`

## Phase I — verify

On `deployment`:

```bash
./deployment/95-verify-openstack.sh
```

On `controller`:

```bash
sudo docker ps --filter name=horizon
```

Horizon:

```text
http://10.0.0.254
```

On the service VMs, the role verification scripts can also be run after deployment:

```bash
sudo ~/kolla-homelab-automation/nodes/controller/10-verify.sh
sudo ~/kolla-homelab-automation/nodes/compute1/10-verify.sh
sudo ~/kolla-homelab-automation/nodes/compute2/10-verify.sh
sudo ~/kolla-homelab-automation/nodes/block1/20-verify.sh
```

On `block1`:

```bash
sudo docker ps --filter name=cinder_volume
sudo docker exec cinder_volume mount | grep configfs
sudo docker exec cinder_volume targetcli ls
```

## Re-running

The scripts are designed to be re-run where safe:

- VM creation skips existing domains.
- host mapping insertion is idempotent.
- Kolla installation does not regenerate an existing password file.
- Cinder preparation does not recreate an existing VG or thin pool.
- deployment phases can be run again, but a full Kolla reconfigure is not triggered automatically.
- `init-runonce` is intentionally guarded against duplicate execution.

Do not use `virsh undefine`, `rm`, `wipefs`, `pvcreate`, or `vgcreate` manually on existing lab disks unless you have verified the consequences.

## Kolla-Ansible release and source

The bundle targets Kolla-Ansible `stable/2026.1` and OpenStack `2026.1`, matching the lab deployment. The Git branch is used rather than a fixed commit hash. For byte-for-byte reproducibility over time, record the installed Git commit and Python package versions after the first successful run:

```bash
source ~/venvs/kolla/bin/activate
pip freeze > ~/kolla-ansible-requirements.lock
```

Official references:

- https://docs.openstack.org/kolla-ansible/2026.1/user/quickstart.html
- https://docs.openstack.org/kolla-ansible/2026.1/user/multinode.html
- https://docs.openstack.org/kolla-ansible/2026.1/reference/storage/cinder-guide.html
