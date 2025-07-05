# Mariadb

## Install

```
yum install mariadb-server
systemctl enable --now mariadb
mysql_secure_installation
```

## Config

In `/etc/my.cnf.d/mariadb-server.cnf`:
```
skip-networking=1
```

## Sql

### Connect
```
# mysql -u root -p
```

### Browse
```
SHOW DATABASES;
USE mysql;
SHOW TABLES;
DESCRIBE user;
SELECT Host,User,Password FROM user;
DESCRIBE mytable;
SELECT * FROM mytable;
UPDATE mytable SET col1 = '1.23', col2 = '10' WHERE id=2;
INSERT INTO mytable (name,col1,col2,col3,col4) ('ST','1.23','1','20','40');
DELETE FROM mytable WHERE name LIKE 'somename';
```

### Users

```
CREATE USER alice@localhost identified by 'password';
CREATE USER bob@'%' identified by 'password';
GRANT INSERT, UPDATE, DELETE, SELECT on mydb.* to alice@localhost;
GRANT SELECT on mydb.* to bob@'%';
FLUSH PRIVILEGES;
```

## Dump and Restore

```
mysqldump -u root -p mydb > mydb-backup.sql
mysql -u root -p mydb < mydb-backup.sql
```
 
