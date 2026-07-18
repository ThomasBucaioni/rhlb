# SSH tricks

## Keychain

```
keychain ~/.ssh/myrsaprivkey . ~/.keychain/$HOSTNAME-sh
```

## Sshfs

```
sshfs user@srv:~ ./remdir
```

## Query

```
ssh -Q help
```

## Wake-on-Lan

Install: `dnf install net-tools`
Enable magic packets: `@reboot ethtool -s myif wol g`
Or as service:
```
[Unit]
Description=Enable Wake-on-LAN

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -s enpXsY wol g

[Install]
WantedBy=multi-user.target
```
Boot up: `ether-wake -i otherif mymac`

## Qemu

Direct:
```
virsh -c qemu+ssh://root@myhv/system console myvm
```

Tunnel:
```
virsh vncdisplay myvm # starts at 5900
ssh -L 590X:127.0.0.1:590X root@myhv
remote-viewer vnc://localhost:590X
```

VM config:
```
sudo grubby --update-kernel=ALL --args="console=ttyS0,115200n8"
systemctl enable serial-getty@ttyS0.service
stty rows 50 cols 180
```
