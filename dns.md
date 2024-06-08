# DNS server

Install: `dnf install bind`

## Authoritative

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

