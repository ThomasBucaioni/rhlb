# Local repository

## Home repo

### Mount an iso image

```
mount /mnt/rhel-install/ rhel-a.b-x86_64-dvd.iso
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

check: `yum repolist`

### Add a kickstart file

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
dnf install tftpd-hpa
vi /etc/default/tftpd-hpa
```
Config: `/etc/default/tftpd-hpa`
```
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
```

Mount the iso and copy the content to the Tftp directory:
```
mount /path/to/rh.iso /mnt/iso
cp -R /mnt/iso/install/* /var/lib/tftpboot
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

Restart both the DHCP and TFTP servers: `systemctl restart isc-dhcp-server tftpd-hpa`

Choose the LAN boot device on the client.

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


