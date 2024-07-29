# SMTP server

https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/9/html/System_Administrators_Guide/s1-email-mta.html#s2-email-mta-postfix.

http://www.postfix.org/

## Intro

### Install

```
yum install -y postfix
alternatives --set mta /usr/sendmail.postfix
```

### Services

- master
- pickup
- cleanup
- qmgr
- trivial-rewrites
- smtpd
- lmtpd
- bounce, defer, trace

### Commands

- alternatives
- mail/mailx
- postalias/newaliases
- postconf
- postfix
- postmap
- postqueue/mailq

### Logging

Text file: `/var/log/maillog`

### SELinux

```
ps -AZ | grep postfix
ls -dZ /etc/postfix/ /var/lib/postfix/ /var/spool/postfix
semanage port -l | grep smtp
getsebool -a | grep postfix
```

## Configuration files

- access file: `less /etc/postfix/access`, `postmap /etc/postfix/access`
- canonical file: `/etc/postfix/canonical`, `postmap /etc/postfix/canonical`
- generic file: `/etc/postfix/generic`
- relocated file: 
- transport file:
- virtual file: 
- aliases file:
- master file: `/etc/postfix/master.cf`
- main config: `/etc/postfix/main.cf`

### Local mail server

```
myhostname = srv1.mynet.com
mydomain = mynet.com
myorigin = $myhostname
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
mynetworks = 192.168.1.0/24, 127.0.0.0/8
disable_dns_lookups = yes
```
Check: `postfix check`
Firewall: `firewall-cmd --permanent --add-service smtp`
Restart, enable, status
Default mail transport agent: `alternatives --set mta /usr/sbin/sendmail.postfix`
Send local email: `date | mail -s "This is a local test" user`, `su - user`, `mail`

### Remote client

```
yum install -y postfix
vi /etc/postfix/main.cf
disable_dns_lookups = yes
```
Restart, enable, test: `date | mail -s "This is a remote test" user` 

### Null-client mail relay

```
myhostname = srv2.mynet.com
mydomain = mynet.com
myorigin = $mydomain
inet_interfaces = localhost
mydestination = 
relayhost = srv1.mynet.com
disable_dns_lookups = yes
```

Test: `date | mail -s "This is a null-client relay test" user@mynet.com`

### Mail gateway

```
myhostname = gtw.mynet.com
mydomain = mynet.com
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost
mynetworks = 192.168.1.0/24 127.0.0.0/8
relayhost = srv1.mynet.com
disable_dns_lookups = yes
```

