# Bastion VM

## PxE boot

## Firewall masquerade

```
sysctl -w net.ipv4.ip_forward=1 # To add in /etc/sysctl.d/myconf.conf

# Add zones
firewall-cmd --permanent --zone=external --change-interface=enp1s0
firewall-cmd --permanent --zone=internal --change-interface=enp8s0

# Enable masquerading
firewall-cmd --permanent --zone=external --add-masquerade
firewall-cmd --permanent --zone=internal --add-forward

# Open internal services
firewall-cmd --permanent --zone=internal --add-service=dns
firewall-cmd --permanent --zone=internal --add-service=dhcp
firewall-cmd --permanent --zone=internal --add-service=ntp
firewall-cmd --permanent --zone=internal --remove-icmp-block=echo-reply

# Add the policy to allow traffic
firewall-cmd --permanent --new-policy lan-to-wan
firewall-cmd --permanent --policy lan-to-wan --add-ingress-zone internal
firewall-cmd --permanent --policy lan-to-wan --add-egress-zone external
firewall-cmd --permanent --policy lan-to-wan --set-target ACCEPT

# Reload
firewall-cmd --reload # or reboot
```

## RDP

### Bastion

```
firewall-cmd --permanent  --new-policy=external-to-internal
firewall-cmd --permanent \
  --policy=external-to-internal \
  --add-ingress-zone=external \
  --add-egress-zone=internal
firewall-cmd --permanent \
  --policy=external-to-internal \
  --add-service=icmp
firewall-cmd --policy=external-to-internal \
  --add-port=3389/tcp --add-port=3390/tcp --permanent
```

### Target

```
firewall-cmd --add-port=3389/tcp --add-port=3390/tcp --permanent
firewall-cmd --reload
```

### Host

```
ip route add 192.168.z.0/24 via 192.168.x.y
xfreerdp /v:VM_IP /u:ignored /p:StrongPassword /cert:ignore
```
