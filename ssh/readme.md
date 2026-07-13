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


