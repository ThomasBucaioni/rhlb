# Postfix-MySql configuration

## MySql

### Database 

```
# mysql -u root
> CREATE DATABASE mail;
> USE mail;
> CREATE USER 'madmin'@'localhost' IDENTIFIED BY 'mpassword';  
> GRANT SELECT, INSERT, UPDATE, DELETE ON mail.* TO 'madmin'@'localhost';
> FLUSH PRIVILEGES;
> CREATE TABLE domains (domain varchar(50) NOT NULL, PRIMARY KEY (domain));
> CREATE TABLE users (email varchar(80) NOT NULL, password varchar(128) NOT NULL, PRIMARY KEY (email));
> CREATE TABLE forwardings (source varchar(80) NOT NULL, destination TEXT NOT NULL, PRIMARY KEY (source));
> exit
```

### Postfix config

In `/etc/postfix/mysql_virtual_domains.cf`:
```
user = madmin
password = mpassword
dbname = mail
query = SELECT domain FROM domains WHERE domain='%s'
hosts = 127.0.0.1
```

In `/etc/postfix/mysql_virtual_forwardings.cf`:
```
user = madmin
password = mpassword
dbname = mail
query = SELECT destination FROM forwardings WHERE source='%s'
hosts = 127.0.0.1
```

In `/etc/postfix/mysql_virtual_mailboxes.cf`:
```
user = madmin
password = mpassword
dbname = mail
query = SELECT CONCAT(SUBSTRING_INDEX(email,'@',-1),'/',SUBSTRING_INDEX(email,'@',1),'/') FROM users WHERE email='%s'
hosts = 127.0.0.1
```

In `/etc/postfix/mysql_virtual_email2email.cf`:
```
user = madmin
password = mpassword
dbname = mail
query = SELECT email FROM users WHERE email='%s'
hosts = 127.0.0.1
```

Perm and ownership:
```
chmod o-rwx /etc/postfix/mysql_virtual_*
chown root.postfix /etc/postfix/mysql_virtual_*

groupadd -g 5000 virtmail
useradd -g virtmail -u 5000 -d /var/virtmail -m virtmail
```

## Postfix

```
postconf -e "myhostname = mail.mydomain.net"
postconf -e "mydestination = mail.mydomain.net, localhost, localhost.localdomain"
postconf -e "mynetworks = 127.0.0.0/8"
postconf -e "message_size_limit = 31457280"
postconf -e "virtual_alias_domains ="
postconf -e "virtual_alias_maps = proxy:mysql:/etc/postfix/mysql_virtual_forwardings.cf, mysql:/etc/postfix/mysql_virtual_email2email.cf"
postconf -e "virtual_mailbox_domains = proxy:mysql:/etc/postfix/mysql_virtual_domains.cf"
postconf -e "virtual_mailbox_maps = proxy:mysql:/etc/postfix/mysql_virtual_mailboxes.cf"
postconf -e "virtual_mailbox_base = /var/virtmail"
postconf -e "virtual_uid_maps = static:5000"
postconf -e "virtual_gid_maps = static:5000"
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "broken_sasl_auth_clients = yes"
postconf -e "smtpd_sasl_authenticated_header = yes"
postconf -e "smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination"
postconf -e "smtpd_use_tls = yes"
postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/mydomain.net/fullchain.pem"
postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/mydomain.net/privkey.pem"
postconf -e "virtual_transport=dovecot"
postconf -e 'proxy_read_maps = $local_recipient_maps $mydestination $virtual_alias_maps $virtual_alias_domains $virtual_mailbox_maps $virtual_mailbox_domains $relay_recipient_maps $relay_domains $canonical_maps $sender_canonical_maps $recipient_canonical_maps $relocated_maps $transport_maps $mynetworks $virtual_mailbox_limit_maps'
```

## SMTP AUTH

### SASLAUTHD

Directory for `saslauthd`:
```
mkdir -p /var/spool/postfix/var/run/saslauthd
```

In `/etc/default/saslauthd`:
```
START=yes
DESC="SASL Authentication Daemon"
NAME="saslauthd"
MECHANISMS="pam"
MECH_OPTIONS=""
THREADS=5
OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd -r"
```

In `/etc/pam.d/smtp`:
```
auth required pam_mysql.so user=madmin passwd=mpassword host=127.0.0.1 db=mail table=users usercolumn=email passwdcolumn=password crypt=3 # debug
account sufficient pam_mysql.so user=madmin passwd=mpassword host=127.0.0.1 db=mail table=users usercolumn=email passwdcolumn=password crypt=3 # debug
```

In `/etc/postfix/sasl/smtpd.conf`:
```
pwcheck_method: saslauthd 
mech_list: plain login 
log_level: 4
```

Perms:
```
chmod o-rwx /etc/pam.d/smtp
chmod o-rwx /etc/postfix/sasl/smtpd.conf

usermod  -aG sasl postfix

systemctl restart postfix
systemctl restart saslauthd
```

## Dovecot

In `/etc/postfix/master.cf`, add:
```
dovecot   unix  -       n       n       -       -       pipe
flags=DRhu user=virtmail:virtmail argv=/usr/lib/dovecot/deliver -d ${recipient}
```

In `/etc/dovecot/dovecot.conf`:
```
log_timestamp = "%Y-%m-%d %H:%M:%S "
mail_location = maildir:/var/virtmail/%d/%n/Maildir
managesieve_notify_capability = mailto
managesieve_sieve_capability = fileinto reject envelope encoded-character vacation subaddress comparator-i;ascii-numeric relational regex imap4flags copy include variables body enotify environment mailbox date
namespace {
  inbox = yes
  location = 
  prefix = INBOX.
  separator = .
  type = private
}
passdb {
  args = /etc/dovecot/dovecot-sql.conf
  driver = sql
}
protocols = imap pop3

service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0660
    user = postfix
  }
  unix_listener auth-master {
    mode = 0600
    user = virtmail
  }
  user = root
}

userdb {
  args = uid=5000 gid=5000 home=/var/virtmail/%d/%n allow_all_users=yes
  driver = static
}

protocol lda {
  auth_socket_path = /var/run/dovecot/auth-master
  log_path = /var/virtmail/dovecot-deliver.log
  mail_plugins = sieve
  postmaster_address = postmaster@example.com
}

protocol pop3 {
  pop3_uidl_format = %08Xu%08Xv
}

service stats {
  unix_listener stats-reader {
    user = dovecot
    group = virtmail
    mode = 0660
  }
  unix_listener stats-writer {
    user = dovecot
    group = virtmail
    mode = 0660
  }
}

ssl = yes
ssl_cert = </etc/letsencrypt/live/mydomain.net/fullchain.pem
ssl_key = </etc/letsencrypt/live/mydomain.net/privkey.pem
```

In `/etc/dovecot/dovecot-sql.conf`:
```
driver = mysql
connect = host=127.0.0.1 dbname=mail user=madmin password=mpassword
default_pass_scheme = PLAIN-MD5
password_query = SELECT email as user, password FROM users WHERE email='%u';
```

Shell: `systemctl restart dovecot`

## Users

```
# mysql -u root
>USE mail;
>INSERT INTO domains (domain) VALUES ('mydomain.net');
>insert into users(email,password) values('alice@mydomain.net', md5('P@ssw0rd123'));
>insert into users(email,password) values('bob@mydomain.net', md5('P@ssw@rd123'));
>quit;
```

## Port SMTPS 465

Check:
```
ss -lntpu | grep 465
```

In `/etc/postfix/master.cf`:
```
smtp    inet    n   -   y   -   -   smtpd -v
smtps   inet    n   -   y   -   -   smtpd -v
```

Restart postfix, and recheck `ss -lntpu`

## Virus scan

### Amavis

Install: `dnf install amavisd`

Set the hostname in `/etc/amavis/conf.d/05-node_id`

In `/etc/postfix/main.cf`:
```
postconf -e 'content_filter = smtp-amavis:[127.0.0.1]:10024'
postconf -e 'smtpd_proxy_options = speed_adjust'
```

In `/etc/postfix/master.cf`:
```
smtp-amavis   unix   -   -   n   -   2   smtp
    -o syslog_name=postfix/amavis
    -o smtp_data_done_timeout=1200
    -o smtp_send_xforward_command=yes
    -o disable_dns_lookups=yes
    -o max_use=20
    -o smtp_tls_security_level=none


127.0.0.1:10025   inet   n    -     n     -     -    smtpd
    -o syslog_name=postfix/10025
    -o content_filter=
    -o mynetworks_style=host
    -o mynetworks=127.0.0.0/8
    -o local_recipient_maps=
    -o relay_recipient_maps=
    -o strict_rfc821_envelopes=yes
    -o smtp_tls_security_level=none
    -o smtpd_tls_security_level=none
    -o smtpd_restriction_classes=
    -o smtpd_delay_reject=no
    -o smtpd_client_restrictions=permit_mynetworks,reject
    -o smtpd_helo_restrictions=
    -o smtpd_sender_restrictions=
    -o smtpd_recipient_restrictions=permit_mynetworks,reject
    -o smtpd_end_of_data_restrictions=
    -o smtpd_error_sleep_time=0
    -o smtpd_soft_error_limit=1001
    -o smtpd_hard_error_limit=1000
    -o smtpd_client_connection_count_limit=0
    -o smtpd_client_connection_rate_limit=0
    -o receive_override_options=no_header_body_checks,no_unknown_recipient_checks,no_address_mappings
```

### ClamAV

Install: `dnf install clamav clamav-daemon` (check RAM requirements)

In `/etc/amavis/conf.d/15-content_filter_mode`: 
```
@bypass_virus_checks_maps = (\%bypass_virus_checks, \@bypass_virus_checks_acl, \$bypass_virus_checks_re);
```

Shell: 
```
useradd -aG amavis clamav
systemctl restart clamav-daemon
systemctl restart amavis
```

## Anti-spam

### Access

[Postfix config](http://www.postfix.org/postconf.5.html)

HELO:
```
smtpd_helo_required = yes
smtpd_helo_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_invalid_helo_hostname,
  reject_non_fqdn_helo_hostname,
  reject_unknown_helo_hostname,
  permit
```

Sender:
```
smtpd_sender_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unknown_sender_domain,
  reject_non_fqdn_sender,
  reject_unknown_reverse_client_hostname,
  reject_unknown_client_hostname,  #could trigger false-positives
  permit
```

Recipient:
```
smtpd_recipient_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unauth_destination,
  reject_unauth_pipelining,
  reject_unknown_recipient_domain,
  reject_non_fqdn_recipient,
#  check_client_access hash:/etc/postfix/rbl_override,
#  reject_rhsbl_helo dbl.spamhaus.org,
#  reject_rhsbl_reverse_client dbl.spamhaus.org,
#  reject_rhsbl_sender dbl.spamhaus.org,
#  reject_rbl_client zen.spamhaus.org,
  permit
```

### Real-time banlist

https://debouncer.com

```
smtpd_recipient_restrictions =
  ...
  check_client_access hash:/etc/postfix/rbl_override,
  reject_rhsbl_helo dbl.spamhaus.org,
  reject_rhsbl_reverse_client dbl.spamhaus.org,
  reject_rhsbl_sender dbl.spamhaus.org,
  reject_rbl_client zen.spamhaus.org,
#  permit
```

Allowlist in `/etc/postfix/rbl_override`:
```
somedomain1.com
somedomain2.com
```
and shell: `postmap /etc/postfix/rbl_override`

### Rspamd (or SpamAssassin, Dspam)

Installs: `dnf install redis-server rspamd`

In `/etc/rspamd/local.d/worker-normal.inc`:
```
    bind_socket = "127.0.0.1:11333";
```

In `/etc/rspamd/local.d/worker-proxy.inc`:
```
    bind_socket = "127.0.0.1:11332";
    milter = yes;
    timeout = 120s;
    upstream "local" {
    default = yes;
    self_scan = yes;
    }
```

Postfix:
```
postconf -e "milter_protocol = 6"
postconf -e "milter_mail_macros = i {mail_addr} {client_addr} {client_name} {auth_authen}"
postconf -e "milter_default_action = accept"
postconf -e "smtpd_milters = inet:127.0.0.1:11332"
postconf -e "non_smtpd_milters = inet:127.0.0.1:11332"
```

Restart rspamd and postfix

## Logs


