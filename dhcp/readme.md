# DHCP v4 v6

## IPv4

### Install

```
yum install dhcp-server
firewall-cmd --permanent --add-service=dhcp
firewall-cmd --permanent --add-service=dhcp --permanent
```

### Conf

```
authoritative;

subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.200 192.168.0.250;
  option broadcast-address 192.168.0.255;
  option domain-name-servers 192.168.0.254;
  option domain-search "myzone.somedom.xyz";
  default-lease-time 600;
  max-lease-time 7200;
}

host srv2 {
  hardware ethernet ab:cd:ef:01:23:45;
  fixed-address 192.168.0.100;
}
```

### Check

```
dhcpd -t
echo $?
systemctl restart dhcpd
```

## IPv6

### Install

```
yum install radvd
radvdump
yum install dhcp-server
firewall-cmd --permanent --add-service=dhcpv6
firewall-cmd --permanent --add-service=dhcpv6 --permanent
journalctl -u dhcpd6.service | grep duid
```

### Conf

```
authoritative;

subnet6 2001:1:2:3::/64 {
  range6 2001:1:2:3::20 2001:1:2:3::60;
  option dhcp6.name-servers 2001:1:2:3::ffff;
  option dhcp6.domain-search "myzone.somedom.xyz";
  default-lease-time 600;
  max-lease-time 7200;
}

host serverc {
  host-identifier option
    dhcp6.client-id 01:23:45:67:89:ab:cd:ef:01:23:45:67:89:ab:cd:ef:01:23;
  fixed-address6 2001:1:2:3::1f;
}
```

### Check

```
dhcpd -t -6 -cf /etc/dhcp/dhcpd6.conf
echo $?
systemctl restart dhcpd6
```
