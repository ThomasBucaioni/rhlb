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

## Gmail + SASL auth

```
compatibility_level = 2
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix
mail_owner = postfix
inet_interfaces = localhost
inet_protocols = all
mydestination = $myhostname, localhost.$mydomain, localhost
unknown_local_recipient_reject_code = 550
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
debug_peer_level = 2
debugger_command =
	 PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin
	 ddd $daemon_directory/$process_name $process_id & sleep 5
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
html_directory = no
manpage_directory = /usr/share/man
sample_directory = /usr/share/doc/postfix/samples
readme_directory = /usr/share/doc/postfix/README_FILES
smtpd_tls_cert_file = /etc/pki/tls/certs/postfix.pem
smtpd_tls_key_file = /etc/pki/tls/private/postfix.key
#smtpd_tls_security_level = may
smtp_tls_CApath = /etc/pki/tls/certs
smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt
smtp_tls_security_level = may
meta_directory = /etc/postfix
shlib_directory = /usr/lib64/postfix

# Custom
mailbox_size_limit = 0
smtpd_banner = $myhostname ESMTP $mail_name (Rocky9)
myhostname = mysrv.mydomain.xyz
mydomain = mydomain.xyz
myorigin = $myhostname
mynetworks = 127.0.0.0/8
relayhost = smtp.gmail.com:587
smtp_sasl_auth_enable = yes
smtpd_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd
smtp_use_tls = yes
smtp_tls_note_starttls_offer = yes
smtp_sasl_mechanism_filter = login, plain
smtpd_tls_security_level = encrypt
```

and `/etc/postfix/sasl/sasl_passwd` : 
```
smtp.gmail.com user@gmail.com:password
```

