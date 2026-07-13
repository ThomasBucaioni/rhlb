# OpenVPN config

## Shared key

### Server

```
dev tun
ifconfig 10.0.10.1 10.0.10.2
secret /etc/openvpn/keys/myvpn.key
local a:b:c:d
cipher AES-256-CBC
auth SHA256
```

### Client

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

## PKI

### Easy-RSA

```
mkdir mypki
cd mypki
easyrsa init-pki
easyrsa build-ca
easyrsa gen-req vpnsrv nopass
easyrsa gen-req vpnclt
easyrsa sign-req server vpnsrv
easyrsa sign-req client vpnclt
easyrsa gen-dh
openvpn --genkey secret ta.key
```

### Server config

Copy: 
- vpnsrv.key
- vpnsrv.crt
- ca.crt
- dh.pem
- ta.key
to `/etc/openvpn/keys`

```
port 1194
proto udp6
dev tun
user nobody
group nobody

ca /etc/openvpn/keys/ca.crt
cert /etc/openvpn/keys/vps.crt
key /etc/openvpn/keys/vps.key
dh /etc/openvpn/keys/dh.pem
tls-auth /etc/openvpn/keys/ta.key 0

server 10.10.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
keepalive 10 120
persist-key
persist-tun
tls-server
remote-cert-tls client

status openvpn-status.log
#verb 4
mute 20
explicit-exit-notify 1
```

### Client config

Copy: 
- vpnclt.key
- vpnclt.crt
- ca.crt
- ta.key
to `/etc/openvpn/keys`

```
client
dev tun
proto udp6
remote c:a:f:e::1 1194

persist-key
persist-tun
resolv-retry infinite
nobind

user nobody
group nobody
tls-client
remote-cert-tls server
#verb 7

ca /etc/openvpn/keys/ca.crt
cert /etc/openvpn/keys/home.crt
key /etc/openvpn/keys/home.key
tls-auth /etc/openvpn/keys/ta.key 1

askpass /etc/openvpn/keys/key.pass
```

## Unit file

Enable: `systemctl enable --now openvpn-X@myconf`

### Server

Template from `systemctl cat openvpn-server@.service`:
```
# /etc/systemd/system/openvpn-server@.service
[Unit]
Description=OpenVPN service for %I
After=syslog.target network-online.target
Wants=network-online.target
Documentation=man:openvpn(8)
Documentation=https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage
Documentation=https://community.openvpn.net/openvpn/wiki/HOWTO

[Service]
Type=notify
PrivateTmp=true
WorkingDirectory=/etc/openvpn/server
ExecStart=/usr/sbin/openvpn --status %t/openvpn-server/status-%i.log --status-version 2 --suppress-timestamps --cipher AES-256-GCM --data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC:AES-128-CBC --config %i.conf
CapabilityBoundingSet=CAP_IPC_LOCK CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW CAP_SETGID CAP_SETUID CAP_SYS_CHROOT CAP_DAC_OVERRIDE CAP_AUDIT_WRITE
LimitNPROC=10
DeviceAllow=/dev/null rw
DeviceAllow=/dev/net/tun rw
ProtectSystem=true
ProtectHome=true
KillMode=process
RestartSec=5s
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Client 

```
[Unit]
Description=OpenVPN tunnel for %i
After=network-online.target
Wants=network-online.target
Documentation=man:openvpn(8)
Documentation=https://openvpn.net/community-resources/reference-manual-for-openvpn-2-7/
Documentation=https://community.openvpn.net/openvpn/wiki/HOWTO

[Service]
Type=notify
PrivateTmp=true
WorkingDirectory=/etc/openvpn/
ExecStart=/usr/sbin/openvpn --suppress-timestamps --nobind --config %i.conf
CapabilityBoundingSet=CAP_IPC_LOCK CAP_NET_ADMIN CAP_NET_RAW CAP_SETGID CAP_SETUID CAP_SETPCAP CAP_SYS_CHROOT CAP_DAC_OVERRIDE CAP_SYS_NICE
TasksMax=20
DeviceAllow=/dev/null rw
DeviceAllow=/dev/net/tun rw
ProtectSystem=true
ProtectHome=true
KillMode=process

[Install]
WantedBy=multi-user.target
```
