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




