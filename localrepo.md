# Local repository

## Home repo

### Mount an iso image

```
mount -o loop,ro -t iso9660 /mnt/rhel-install/ rhel-a.b-x86_64-dvd.iso
```

### Copy the DVD to `/var/www/html`

```
cp -a /mnt/rhel-install /var/www/html/rhel-install
restorecon -Rvv /var/www/html
```

### Make a repo

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

check: `dnf repolist`

### Add a kickstart file

https://access.redhat.com/labs/kickstartconfig/

or pick `/root/anaconda-ks.cfg`

## Twirk the ISO

```
cd /path/to/iso
mkisofs -o ../boot.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -r .
```

## Preboot eXecution Environment

### DHCP server

Install on RH:
```
dnf install dhcp-server
```
and config':
```
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 10.0.1.0 netmask 255.255.255.0 {
	range 10.0.1.3 10.0.1.200;
	option subnet-mask 255.255.255.0;
	option routers 10.0.1.1;
	option domain-name-servers 10.0.1.1, 1.1.1.1;
	option domain-search "myrhcsa.net";
	host rhcsa-clt {
	  hardware ethernet 52:54:00:b1:0b:10;
	  fixed-address 10.0.1.2;
	}
}
```
and client: `nmcli con mod rhcsa-in ipv4.method auto`

### TFTP server

```
dnf install tftp-server
cp -r /usr/share/syslinux/* /var/lib/tftpboot/
```

Mount the iso and copy the content to the Tftp directory:
```
mount /path/to/rh.iso /mnt/iso
cp -R /mnt/iso/install/* /var/lib/tftpboot/elX
```

Add in `/etc/dhcp/dhcpd.conf`
```
subnet ...{
    ...
    allow booting;
    arrom bootp;
    next-server 10.0.1.1; # this server
    filename "pxelinux.0"; 
}
```

Restart both the DHCP and TFTP servers: `systemctl restart dhcpd tftpd`

Add PxE menu in `/var/lib/tftpboot/pxelinux.cfg/default`:
```
default menu.c32
prompt 0
timeout 20
#ONTIMEOUT local

label el9
    menu label ^Install RHEL 9.3
    kernel el9/images/pxeboot/vmlinuz inst.ks=http://192.168.101.1/rhel-install/anaconda-ks.cfg inst.repo=http://192.168.101.1/rhel-install
    append initrd=el9/images/pxeboot/initrd.img
```

Choose the LAN boot device on the client.

## Libvirt

### Virsh volume

```
virsh vol-create-as --pool mypool --name rhelguest-vda.qcows2 --format qcows2 –capacity 10G
```

### Virt-install

Simple version:
```
virt-install --name rhkshost --vcpus=8 --memory=8192 --disk path=/libvirt/images/rhkshost.qcow2,format=qcow2,size=20 --location="/bigfiles/Rhel-a.b-x86_64.iso --initrd-inject="$HOME/rhel-install/anaconda-ks.cfg" --extra-args="inst.ks=file:/anaconda-ks.cfg inst.ip=dhcp inst.console=ttyS0,115200n8" --os-variant=rhela.b --machine=q35 --boot=uefi
```

Full strike:
```
virt-install \
--hvm \
--name rhelguest-vm \
–-memory 2G,maxmemory=4G \
--vcpus 2,max=4 \
--os-type linux \
--os-variant rhel9 \
--boot hd,cdrom,network,menu=on \
--controller type=scsi,model=virtio-scsi \
--disk device=cdrom,vol=/path/to/iso/boot.iso,readonly=on,bus=scsi \
--disk device=disk,vol=mypool/rhelguest-vda.qcow2,cache=none,bus=scsi \
--network network=bridge-eth0,model=virtio \
--graphics vnc \
--graphics spice \
--noautoconsole \
--memballoon virtio
```

### Virsh connection

Connect to a VM:
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


