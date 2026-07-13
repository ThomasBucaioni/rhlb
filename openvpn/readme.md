# OpenVPN config

## Server

```
dev tun
ifconfig 10.0.10.1 10.0.10.2
secret /etc/openvpn/keys/myvpn.key
local a:b:c:d
cipher AES-256-CBC
auth SHA256
```

## Client

```
dev tun
ifconfig 10.0.10.2 10.0.10.1
secret /etc/openvpn/keys/myvpn.key
remote a:b:c:d
cipher AES-256-CBC
auth SHA256
allow-deprecated-insecure-static-crypto
```

and open port UDP 1194.
