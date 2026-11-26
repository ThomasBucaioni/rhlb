# Kickstart / libvirt VM provisioning

Reconstructed RHEL 10 homelab framework. The profiles are examples, not copies of the original host configurations. Keycloak, monitoring and Ansible are baseline placeholders, not service installers.

## Requirements
RHEL 10 KVM host, Python 3, libvirt, virt-install, pykickstart, a RHEL 10 DVD ISO, an active storage pool and Linux bridge, and an SSH public key. Check `osinfo-query os` for the installed RHEL 10 identifier. Run with permissions to manage system libvirt.

## Usage
Edit the chosen `vm.json` first: the example addresses use the non-routable documentation network 192.0.2.0/24. Set hostname, interface, DNS, gateway, CPU, RAM and disk size. `link` selects the first linked interface. The default installation assumes a single virtio disk (`vda`).

```bash
python3 generate-ks.py dns-lb --ssh-key ~/.ssh/id_ed25519.pub
ksvalidator -v RHEL10 build/dns-lb.ks.cfg
python3 create-vm.py dns-lb --ssh-key ~/.ssh/id_ed25519.pub --iso /path/to/rhel-10.2-dvd.iso --pool vmdata --bridge br0
# Repeat with --apply to actually create the VM.
sudo virsh console dns-lb
```

The installer initrd is injected with the generated Kickstart at boot via virt-install (the ISO itself is not modified). The default is a dry run; `--apply` validates and checks existing domains and potential volumes. Kickstart clears the guest vda disk. Never use it on a machine containing data you need. The lab user has passwordless sudo and key-based access; adapt this policy before production use. Register the installed RHEL guest separately if required for updates. No subscription credentials or private keys are included.

## Layout
`common/` holds the shared template and post-install script; each profile contains `vm.json`; `build/` contains generated files and is ignored by Git. The `templates/` directory documents the template approach. The historical `okdverify.sh` is not included because its source was unavailable.

## Verification
Run `python3 -m unittest discover -s tests`. This tests generation only. Actual Anaconda installation and libvirt provisioning require a RHEL host and have not been tested in the packaging environment.
