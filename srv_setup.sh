#!/bin/bash
IP_ADDR=$srvip
HOSTNAME=rhcsa-srv.myldm.net
SHORTNAME=rhcsa-srv
DOMAIN=myldm.net
REALM=MYLDM.NET
LDAPHOME=/home/ldap
GATEWAY=$kvmgw

yum install -y ipa-server ipa-server-dns bind-dyndb-ldap

echo "$IP_ADDR $HOSTNAME $SHORTNAME" >> /etc/hosts

# IPA server install (beware, timeouts on the reverse zone...)
ipa-server-install --domain=$DOMAIN --realm=$REALM --ds-password=password --admin-password=password --hostname=$HOSTNAME --ip-address=$IP_ADDR --reverse-zone=c.b.a.in-addr.arpa. --forwarder=$GATEWAY --allow-zone-overlap --setup-dns --unattended

for i in http https ldap ldaps kerberos kpasswd dns ntp ; do 
	firewall-cmd --permanent --add-service $i
done

firewall-cmd --reload

echo -n 'password' | kinit admin # Kerberos ticket for the rest of the configuration

ipa config-mod --homedirectory=$LDAPHOME # Changing default home directory on new user

# NFS
yum -y install nfs-utils
systemctl enable rpcbind --now
systemctl enable nfs-server --now

mkdir $LDAPHOME
mkdir /srv/nfs
chown nobody /srv/nfs

echo "$LDAPHOME *(rw)" >> /etc/exports
echo "/srv/nfs *(rw)" >> /etc/exports

firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload

cd $LDAPHOME
# Creating LDAP users
ipa user-add ldapuser --first=ldapuserfirst --last=ldapuserlast
ipa user-add ldapadmin --first=ldapadminfirst --last=ldapadminlast

echo 'password' | ipa passwd ldapuser
echo 'password' | ipa passwd ldapadmin

# Samba
mkdir /srv/samba
chmod 2775 /srv/samba
mkdir /srv/public
chmod 777 /srv/public

groupadd userssamba
chown -R :userssamba /srv/samba

# Installing Samba
yum -y install samba
systemctl enable smb --now
systemctl enable nmb --now

touch /srv/samba/samba-user
useradd sambauser -G userssamba
printf "password\npassword\n" | smbpasswd -a -s sambauser

firewall-cmd --add-service samba --permanent
firewall-cmd --reload

# Editing the smb.conf
echo "[data]" >> /etc/samba/smb.conf
echo "comment = data share" >> /etc/samba/smb.conf
echo "path = /srv/samba" >> /etc/samba/smb.conf
echo "write list = @userssamba" >> /etc/samba/smb.conf

sed -i '/\[global\]/a map to guest = bad user' /etc/samba/smb.conf

echo "[public]" >> /etc/samba/smb.conf
echo "comment = Public Directory" >> /etc/samba/smb.conf
echo "path = /srv/public" >> /etc/samba/smb.conf
echo "browseable = yes" >> /etc/samba/smb.conf
echo "writable = yes" >> /etc/samba/smb.conf
echo "guest ok = yes" >> /etc/samba/smb.conf
echo "read only = no" >> /etc/samba/smb.conf

semanage fcontext -a -t samba_share_t "/srv/samba(/.*)?"
semanage fcontext -a -t samba_share_t "/srv/public(/.*)?"
restorecon -Rv /srv

systemctl restart smb
systemctl restart nmb


