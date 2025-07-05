# DNS server

Install: `dnf install bind`

## Authoritative

### Primary

#### Conf

In `/etc/named.conf`:
```
options {
	listen-on port 53 { 127.0.0.1; x; y; z; };
	listen-on-v6 port 53 { ::1; };
	allow-transfer { localhost; x; y; z; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	secroots-file	"/var/named/data/named.secroots";
	recursing-file	"/var/named/data/named.recursing";
	allow-query     { any; };

	//recursion no;
	allow-recursion { localhost; x; y; z; };

	dnssec-validation yes;

	managed-keys-directory "/var/named/dynamic";
	geoip-directory "/usr/share/GeoIP";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";

	/* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
	include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

zone "myzone.com" IN {
	type master;
	file "myzone.com.fwd.zone";
	//allow-update { none; };
};

zone "c.b.a.in-addr.arpa" {
	type master;
	file "myzone.com.rev.zone";
	//allow-update { none; };
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
```

#### Forward zone

In `/var/named/myzone.com.fwd.com`:
```
$TTL 3600
@	IN SOA ns1.myzone.com. root.myzone.com. (
	2024081001 ; serial
	3600; refresh
	1800; retry
	604800; expire
	86400); minimum

@	IN	NS	ns1.myzone.com
@	IN	NS	ns2.myzone.com
@	IN	NS	ns3.myzone.com
ns1	IN	A	x
ns2	IN	A	y
ns3	IN	A	z
ns1	IN	AAAA	X
ns2	IN	AAAA    Y
ns2	IN	AAAA	Z
www	IN	A	z
dev	IN	A	y
mysrv	IN	A	x
	IN	TXT	"v=spf1 -all"
*._domainkey	IN	TXT	"v=DKIM1; p="
_dmarc	IN	TXT	"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s"
@ 	IN	MX	10	smtp.myzone.com.
smtp 	IN	A	x
```

#### Reverse zone

In `/var/named/myzone.com.rev.zone`:
```
$TTL 86400
@	IN SOA ns1.myzone.com. root.myzone.com. (
	2024080702 ; serial
	3600; refresh
	1800; retry
	604800; expire
	86400); minimum

@	IN	NS	ns1.
x	IN	PTR	ns1.myzone.com.
```
### Secondary

```
options {
	listen-on port 53 { 127.0.0.1; x; y; z;};
	listen-on-v6 port 53 { ::1; };
	allow-transfer { localhost; x; y; z; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	secroots-file	"/var/named/data/named.secroots";
	recursing-file	"/var/named/data/named.recursing";
	allow-query     { any; };

	//recursion no;
	allow-recursion { localhost; x; y; z; };

	dnssec-validation yes;

	managed-keys-directory "/var/named/dynamic";
	geoip-directory "/usr/share/GeoIP";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";

	/* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
	include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

zone "myzone.com" IN {
	type slave;
	file "myzone.com.fwd.zone";
	masters { x; };
};

zone "c.b.a.in-addr.arpa" {
	type slave;
	file "myzone.com.rev.zone";
	masters { x; };
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
```

## Caching and forwarding

Config' in `/etc/named.conf`: 
```
options {
	listen-on port 53 { any; };
	allow-query     { any; };
	recursion yes;
	dnssec-validation no;
    ...
}
```

## Unbound

```
yum install unbound
unbound-control-setup
unbound-checkconf
firewall-cmd --permanent --add-service=dns
firewall-cmd --reload
systemctl enable --now unbound
unbound-control dump_cache
unbound-control srv1.myzone.somedom.xyz
```

