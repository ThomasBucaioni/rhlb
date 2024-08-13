# Postfix-MySql configuration

## MySql

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


