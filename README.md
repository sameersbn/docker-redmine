# Table of Contents
- [Introduction](#introduction)
    - [Version](#version)
    - [Changelog](Changelog.md)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
    - [Data Store](#data-store)
    - [Database](#database)
        - [MySQL](#mysql)
            - [Internal MySQL Server](#internal-mysql-server)
            - [External MySQL Server](#external-mysql-server)
    - [Mail](#mail)
    - [Putting it all together](#putting-it-all-together)
    - [Available Configuration Parameters](#available-configuration-parameters)
- [Maintenance](#maintenance)
    - [SSH Login](#ssh-login)
- [Upgrading](#upgrading)
- [References](#references)

# Introduction
Dockerfile to build a Redmine container image (with some additional themes and plugins).

## Version
Current Version: 2.5.0

# Installation

Pull the image from the docker index. This is the recommended method of installation as it is easier to update image in the future. These builds are performed by the Trusted Build service.

```
docker pull sameersbn/redmine:latest
```

Since version 2.4.2, the image builds are being tagged. You can now pull a particular version of redmine by specifying the version number. For example,

```
docker pull sameersbn/redmine:2.5.0
```

Alternately you can build the image yourself.

```
git clone https://github.com/sameersbn/docker-redmine.git
cd docker-redmine
docker build -t="$USER/redmine" .
```

# Quick Start
Run the redmine image with the name "redmine".

```
docker run -name redmine -d sameersbn/redmine:latest
REDMINE_IP=$(docker inspect redmine | grep IPAddres | awk -F'"' '{print $4}')
```

Access the Redmine application

```
xdg-open "http://${REDMINE_IP}"
```

__NOTE__: Please allow a minute or two for the Redmine application to start.

Login using the default username and password:

* username: admin
* password: admin

You should now have Redmine ready for testing. If you want to use Redmine for more than just testing then please read the **Advanced Options** section.

# Configuration

## Data Store
For the file storage we need to mount a volume at the following location.

* /redmine/files

Volumes can be mounted in docker by specifying the **'-v'** option in the docker run command.

```
mkdir -pv /opt/redmine/files
docker run -name redmine -d \
  -v /opt/redmine/files:/redmine/files sameersbn/redmine:latest
```

## Database

Redmine uses a database backend to store its data.

### Internal MySQL Server
This docker image is configured to use a MySQL database backend. The database connection can be configured using environment variables. If not specified, the image will start a mysql server internally and use it. However in this case, the data stored in the mysql database will be lost if the container is stopped/deleted. To avoid this you should mount a volume at /var/lib/mysql.

```
mkdir /opt/redmine/mysql
docker run -name redmine -d \
  -v /opt/redmine/files:/redmine/files \
  -v /opt/redmine/mysql:/var/lib/mysql sameersbn/redmine:latest
```

This will make sure that the data stored in the database is not lost when the image is stopped and started again.

#### External MySQL Server
The image can be configured to use an external MySQL database instead of starting a MySQL server internally. The database configuration should be specified using environment variables while starting the Redmine image.

Before you start the Redmine image create user and database for redmine.

```
mysql -uroot -p
CREATE USER 'redmine'@'%.%.%.%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS `redmine_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `redmine_production`.* TO 'redmine'@'%.%.%.%';
```

*Assuming that the mysql server host is 192.168.1.100*

```
docker run -name redmine -d \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=redmine_production" \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/files:/redmine/files sameersbn/redmine:latest
```

This will initialize the redmine database and after a couple of minutes your redmine instance should be ready to use.

### Mail
The mail configuration should be specified using environment variables while starting the redmine image. The configuration defaults to using gmail to send emails and requires the specification of a valid username and password to login to the gmail servers.

The following environment variables need to be specified to get mail support to work.

* SMTP_DOMAIN (defaults to www.gmail.com)
* SMTP_HOST (defaults to smtp.gmail.com)
* SMTP_PORT (defaults to 587)
* SMTP_USER
* SMTP_PASS

```
docker run -name redmine -d \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  -v /opt/redmine/files:/redmine/files sameersbn/redmine:latest
```

If you are not using google mail, then please configure the  SMTP host and port using the SMTP_HOST and SMTP_PORT configuration parameters.

__NOTE:__

I have only tested standard gmail and google apps login. I expect that the currently provided configuration parameters should be sufficient for most users. If this is not the case, then please let me know.

### Putting it all together

```
docker run -name redmine -d -h redmine.local.host \
  -v /opt/redmine/files:/redmine/files \
  -v /opt/redmine/mysql:/var/lib/mysql \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/redmine:latest
```

If you are using an external mysql database

```
docker run -name redmine -d -h redmine.local.host \
  -v /opt/redmine/files:/redmine/files \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=redmine_production" -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/redmine:latest
```

### Available Configuration Parameters

Below is the complete list of parameters that can be set using environment variables.

- **DB_HOST**: The mysql server hostname. Defaults to localhost.
- **DB_PORT**: The mysql server port. Defaults to 3306.
- **DB_NAME**: The mysql database name. Defaults to redmine_production
- **DB_USER**: The mysql database user. Defaults to root
- **DB_PASS**: The mysql database password. Defaults to no password
- **DB_POOL**: The mysql database connection pool count. Defaults to 5.
- **MEMCACHED_SIZE**: The local memcached size in Mb. Defaults to 64. Disabled if '0'.
- **SMTP_DOMAIN**: SMTP domain. Defaults to www.gmail.com
- **SMTP_HOST**: SMTP server host. Defaults to smtp.gmail.com.
- **SMTP_PORT**: SMTP server port. Defaults to 587.
- **SMTP_USER**: SMTP username.
- **SMTP_PASS**: SMTP password.
- **PASSENGER_MAX_POOL_SIZE**: PassengerMaxPoolSize (default: 6)
- **PASSENGER_MIN_INSTANCES**: PassengerMinInstances (default: 1)
- **PASSENGER_MAX_REQUESTS**: PassengerMaxRequests (default: 0)
- **PASSENGER_POOL_IDLE_TIME**: PassengerPoolIdleTime (default: 300)

## Maintenance

### SSH Login
There are two methods to gain root login to the container, the first method is to add your public rsa key to the authorized_keys file and build the image.

The second method is use the dynamically generated password. Every time the container is started a random password is generated using the pwgen tool and assigned to the root user. This password can be fetched from the docker logs.

```
docker logs redmine 2>&1 | grep '^User: ' | tail -n1
```
This password is not persistent and changes every time the image is executed.

## Upgrading

To upgrade to newer redmine releases, simply follow this 5 step upgrade procedure.

**Step 1**: Stop the currently running image

```
docker stop redmine
```

**Step 2**: Backup the database in case something goes wrong.

```
mysqldump -h <mysql-server-ip> -uredmine -p --add-drop-table redmine_production > redmine.sql
```

**Step 3**: Update the docker image.

```
docker pull sameersbn/redmine:latest
```

**Step 4**: Migrate the database.

```
docker run -name redmine -i -t -rm [OPTIONS] sameersbn/redmine:latest app:db:migrate
```

**Step 5**: Start the image

```
docker run -name redmine -i -d [OPTIONS] sameersbn/redmine:latest
```

## References
  * http://www.redmine.org/
  * http://www.redmine.org/projects/redmine/wiki/Guide
  * http://www.redmine.org/projects/redmine/wiki/RedmineInstall
