# Apache

## Security

### Firewalld

```
firewall-cmd --add-service=http --add-service=https --permanent
firewall-cmd --reload
```

### Selinux

```
semanage fcontext -a -t httpd_sys_content_t /srv/virt/www/'(/.*)?'
restorecon -rv /srv/virt/www
semanage port -a -t http_port_t -p tcp 81
```

## Virtual hosts

### HTTP

```
<VirtualHost *:80>
	ServerName mydomain.net
	ServerAlias www.mydomain.net
	DocumentRoot /var/www/mydomain.net

	ServerAdmin webmaster@mydomain.net
	ErrorLog /var/log/apache2/mydomain.net_error.log
	CustomLog /var/log/apache2/mydomain.net_access.log combined


RewriteEngine on
RewriteCond %{SERVER_NAME} =mydomain.net [OR]
RewriteCond %{SERVER_NAME} =www.mydomain.net
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
```

## OpenSSL and _Let's Encrypt_

https://letsencrypt.org

Installs: `dnf install certbot python3-certbot-apache`

Shell: `certbot -d mydomain.net`

Check renewal: 
```
systemctl status certbot.timer
certbot renew --dry-run
```

### HTTPS

```
<IfModule mod_ssl.c>
<VirtualHost *:443>
	ServerName mydomain.net
	ServerAlias www.mydomain.net
	DocumentRoot /var/www/mydomain.net

	ServerAdmin webmaster@mydomain.net
	ErrorLog /var/log/apache2/mydomain.net_error.log
	CustomLog /var/log/apache2/mydomain.net_access.log combined



SSLCertificateFile /etc/letsencrypt/live/mydomain.net/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/mydomain.net/privkey.pem
Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>
```


