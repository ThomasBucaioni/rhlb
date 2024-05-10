# Local repository

## Mount an iso image

```
mount /mnt/rhel-install/ rhel-a.b-x86_64-dvd.iso
```

## Copy the DVD to `/var/www/html`

```
cp -a /mnt/rhel-install /var/www/html/rhel-install
restorecon -Rvv /var/www/html
```

## Make a repo

In `/etc/yum.repo.d/unattended.repo`:
```
[BaseOS]
name=BaseOS
baseurl=file:///var/www/html/rhel-install/BaseOS
enabled=1
gpgcheck=0

[AppStream]
name=AppStream
baseurl=file:///var/www/html/rhel-install/AppStream
enabled=1
gpgcheck=0
```

check: `yum repolist`

## Add a kickstart file

https://access.redhat.com/labs/kickstartconfig/

or pick `/root/anaconda-ks.cfg`

## Twirk the ISO

```
cp -a ...
ks=...
mkisofs ...
```

## Preboot eXecution Environment

### DHCP server

```
dnf install isc-dhcp-server
```

### HTTP server
```
ks=nfs:a.b.c.d/ks.cfg
```

### TFTP server

```
dnf install tftpd-hpa
vi /etc/default/tftpd-hpa
```

## Libvirt

### Virt-install

```
virt-install --name rhkshost --memory=4096 --disk path=/libvirt/images/rhkshost.qcow2,format=qcow2,size=20 --location="/bigfiles/Rhel-a.b-x86_64.iso --initrd-inject="$HOME/rhel-install/anaconda-ks.cfg" --extra-args="inst.ks=file:/anaconda-ks.cfg inst.ip=dhcp inst.console=ttyS0,115200n8" --os-variant=rhela.b --machine=q35 --boot=uefi
```

### Virsh

```
# virsh
> list --all
> dominfo rhkshost
> start rhkshost
> console rhkshost
> > ^]
> autostart rhkshost
> shutdown rhkshost
> quit
```

### Virt-*

```
virt-clone --auto-clone --original rhkshost --name rhkshost-clone
```


