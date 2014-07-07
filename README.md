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
            - [Linking to MySQL Container](#linking-to-mysql-container)
        - [PostgreSQL](#postgresql)
            - [External PostgreSQL Server](#external-postgresql-server)
            - [Linking to PostgreSQL Container](#linking-to-postgresql-container)
    - [Mail](#mail)
    - [Putting it all together](#putting-it-all-together)
    - [Available Configuration Parameters](#available-configuration-parameters)
- [Upgrading](#upgrading)
- [References](#references)

# Introduction
Dockerfile to build a Redmine container image (with some additional themes and plugins).

## Version
Current Version: 2.5.2

# Installation

Pull the image from the docker index. This is the recommended method of installation as it is easier to update image in the future. These builds are performed by the Trusted Build service.

```
docker pull sameersbn/redmine:latest
```

Since version 2.4.2, the image builds are being tagged. You can now pull a particular version of redmine by specifying the version number. For example,

```
docker pull sameersbn/redmine:2.5.2
```

Alternately you can build the image yourself.

```
git clone https://github.com/sameersbn/docker-redmine.git
cd docker-redmine
docker build --tag="$USER/redmine" .
```

# Quick Start
Run the redmine image with the name "redmine".

```
docker run --name redmine -d sameersbn/redmine:2.5.2
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
docker run --name redmine -d \
  -v /opt/redmine/files:/redmine/files sameersbn/redmine:2.5.2
```

## Database

Redmine uses a database backend to store its data.

### Internal MySQL Server

> **Warning**
>
> The internal mysql server will soon be removed from the image.

> Please use a linked [mysql](#linking-to-mysql-container) or
> [postgresql](#linking-to-postgresql-container) container instead.
> Or else connect with an external [mysql](#external-mysql-server) or
> [postgresql](#external-postgresql-server) server.

> You've been warned.

This docker image is configured to use a MySQL database backend. The database connection can be configured using environment variables. If not specified, the image will start a mysql server internally and use it. However in this case, the data stored in the mysql database will be lost if the container is stopped/deleted. To avoid this you should mount a volume at /var/lib/mysql.

```
mkdir /opt/redmine/mysql
docker run --name redmine -d \
  -v /opt/redmine/files:/redmine/files \
  -v /opt/redmine/mysql:/var/lib/mysql sameersbn/redmine:2.5.2
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

Now that we have the database created for redmine, lets install the database schema. This is done by starting the redmine container with the **app:db:migrate** command.

*Assuming that the mysql server host is 192.168.1.100*

```
docker run --name redmine -i -t --rm \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=redmine_production" \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/files:/redmine/files sameersbn/redmine:2.5.2 app:db:migrate
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the redmine application.

```
docker run --name redmine -d \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=redmine_production" \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/files:/redmine/files sameersbn/redmine:2.5.2
```

This will initialize the redmine database and after a couple of minutes your redmine instance should be ready to use.

#### Linking to MySQL Container
You can link this image with a mysql container for the database requirements. The alias of the mysql server container should be set to **mysql** while linking with the redmine image.

If a mysql container is linked, only the DB_HOST and DB_PORT settings are automatically retrieved using the linkage. You may still need to set other database connection parameters such as the DB_NAME, DB_USER, DB_PASS and so on.

To illustrate linking with a mysql container, we will use the [sameersbn/mysql](https://github.com/sameersbn/docker-mysql) image. When using docker-mysql in production you should mount a volume for the mysql data store. Please refer the [README](https://github.com/sameersbn/docker-mysql/blob/master/README.md) of docker-mysql for details.

First, lets pull the mysql image from the docker index.
```bash
docker pull sameersbn/mysql:latest
```

For data persistence lets create a store for the mysql and start the container.
```bash
mkdir -p /opt/mysql/data
docker run --name mysql -d \
  -v /opt/mysql/data:/var/lib/mysql \
  sameersbn/mysql:latest
```

You should now have the mysql server running. By default the sameersbn/mysql image does not assign a password for the root user and allows remote connections for the root user from the 172.17.%.% address space. This means you can login to the mysql server from the host as the root user.

Now, lets login to the mysql server and create a user and database for the redmine application.

```bash
mysql -uroot -h $(docker inspect mysql | grep IPAddres | awk -F'"' '{print $4}')
```

```sql
CREATE USER 'redmine'@'172.17.%.%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS `redmine_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `redmine_production`.* TO 'redmine'@'172.17.%.%';
FLUSH PRIVILEGES;
```

Now that we have the database created for redmine, lets install the database schema. This is done by starting the redmine container with the **app:db:migrate** command.

```bash
docker run --name redmine -i -t --rm --link mysql:mysql \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "DB_NAME=redmine_production" \
  -v /opt/redmine/files:/redmine/files \
  sameersbn/redmine:2.5.2 app:db:migrate
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the redmine application.

```bash
docker run --name redmine -d --link mysql:mysql \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "DB_NAME=redmine_production" \
  -v /opt/redmine/files:/redmine/files \
  sameersbn/redmine:2.5.2
```

### PostgreSQL

#### External PostgreSQL Server
The image also supports using an external PostgreSQL Server. This is also controlled via environment variables.

```sql
CREATE ROLE redmine with LOGIN CREATEDB PASSWORD 'password';
CREATE DATABASE redmine_production;
GRANT ALL PRIVILEGES ON DATABASE redmine_production to redmine;
```

Now that we have the database created for redmine, lets install the database schema. This is done by starting the redmine container with the **app:db:migrate** command.

*Assuming that the PostgreSQL server host is 192.168.1.100*

```bash
docker run --name redmine -i -t --rm \
  -e "DB_TYPE=postgres" -e "DB_HOST=192.168.1.100" \
  -e "DB_NAME=redmine_production" -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/files:/redmine/files \
  sameersbn/redmine:2.5.2 app:db:migrate
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the redmine application.

```bash
docker run --name redmine -d \
  -e "DB_TYPE=postgres" -e "DB_HOST=192.168.1.100" \
  -e "DB_NAME=redmine_production" -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/files:/redmine/files \
  sameersbn/redmine:2.5.2
```

This will initialize the redmine database and after a couple of minutes your redmine instance should be ready to use.

#### Linking to PostgreSQL Container
You can link this image with a postgresql container for the database requirements. The alias of the postgresql server container should be set to **postgresql** while linking with the redmine image.

If a postgresql container is linked, only the DB_HOST and DB_PORT settings are automatically retrieved using the linkage. You may still need to set other database connection parameters such as the DB_NAME, DB_USER, DB_PASS and so on.

To illustrate linking with a postgresql container, we will use the [sameersbn/postgresql](https://github.com/sameersbn/docker-postgresql) image. When using postgresql image in production you should mount a volume for the postgresql data store. Please refer the [README](https://github.com/sameersbn/docker-postgresql/blob/master/README.md) of docker-postgresql for details.

First, lets pull the postgresql image from the docker index.
```bash
docker pull sameersbn/postgresql:latest
```

For data persistence lets create a store for the postgresql and start the container.
```bash
mkdir -p /opt/postgresql/data
docker run --name postgresql -d \
  -v /opt/postgresql/data:/var/lib/postgresql \
  sameersbn/postgresql:latest
```

You should now have the postgresql server running. The password for the postgres user can be found in the logs of the postgresql image.

```bash
docker logs postgresql
```

Now, lets login to the postgresql server and create a user and database for the redmine application.

```bash
POSTGRESQL_IP=$(docker inspect postgresql | grep IPAddres | awk -F'"' '{print $4}')
psql -U postgres -h ${POSTGRESQL_IP}
```

```sql
CREATE ROLE redmine with LOGIN CREATEDB PASSWORD 'password';
CREATE DATABASE redmine_production;
GRANT ALL PRIVILEGES ON DATABASE redmine_production to redmine;
```

Now that we have the database created for redmine, lets install the database schema. This is done by starting the redmine container with the **app:db:migrate** command.

```bash
docker run --name redmine -i -t --rm --link postgresql:postgresql \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "DB_NAME=redmine_production" \
  -v /opt/redmine/files:/redmine/files \
  sameersbn/redmine:2.5.2 app:db:migrate
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the redmine application.

```bash
docker run --name redmine -d --link postgresql:postgresql \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "DB_NAME=redmine_production" \
  -v /opt/redmine/files:/redmine/files \
  sameersbn/redmine:2.5.2
```

### Mail
The mail configuration should be specified using environment variables while starting the redmine image. The configuration defaults to using gmail to send emails and requires the specification of a valid username and password to login to the gmail servers.

The following environment variables need to be specified to get mail support to work.

* SMTP_DOMAIN (defaults to www.gmail.com)
* SMTP_HOST (defaults to smtp.gmail.com)
* SMTP_PORT (defaults to 587)
* SMTP_USER
* SMTP_PASS
* SMTP_STARTTLS (defaults to true)
* SMTP_AUTHENTICATION (defaults to ':login' if SMTP_USER is set)

```
docker run --name redmine -d \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  -v /opt/redmine/files:/redmine/files sameersbn/redmine:2.5.2
```

If you are not using google mail, then please configure the  SMTP host and port using the SMTP_HOST and SMTP_PORT configuration parameters.

__NOTE:__

I have only tested standard gmail and google apps login. I expect that the currently provided configuration parameters should be sufficient for most users. If this is not the case, then please let me know.

### Putting it all together

```
docker run --name redmine -d -h redmine.local.host \
  -v /opt/redmine/files:/redmine/files \
  -v /opt/redmine/mysql:/var/lib/mysql \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/redmine:2.5.2
```

If you are using an external mysql database

```
docker run --name redmine -d -h redmine.local.host \
  -v /opt/redmine/files:/redmine/files \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=redmine_production" -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/redmine:2.5.2
```

### Available Configuration Parameters

*Please refer the docker run command options for the `--env-file` flag where you can specify all required environment variables in a single file. This will save you from writing a potentially long docker run command.*

Below is the complete list of parameters that can be set using environment variables.

- **DB_TYPE**: The database type. Possible values: mysql, postgres. Defaults to mysql.
- **DB_HOST**: The database server hostname. Defaults to localhost.
- **DB_PORT**: The database server port. Defaults to 3306.
- **DB_NAME**: The database name. Defaults to redmine_production
- **DB_USER**: The database user. Defaults to root
- **DB_PASS**: The database password. Defaults to no password
- **DB_POOL**: The database connection pool count. Defaults to 5.
- **NGINX_MAX_UPLOAD_SIZE**: Maximum acceptable upload size. Defaults to 20m.
- **UNICORN_WORKERS**: The number of unicorn workers to start. Defaults to 2.
- **UNICORN_TIMEOUT**: Sets the timeout of unicorn worker processes. Defaults to 60 seconds.
- **MEMCACHED_SIZE**: The local memcached size in Mb. Defaults to 64. Disabled if '0'.
- **SMTP_DOMAIN**: SMTP domain. Defaults to www.gmail.com
- **SMTP_HOST**: SMTP server host. Defaults to smtp.gmail.com.
- **SMTP_PORT**: SMTP server port. Defaults to 587.
- **SMTP_USER**: SMTP username.
- **SMTP_PASS**: SMTP password.
- **SMTP_STARTTLS**: Enable STARTTLS. Defaults to true.
- **SMTP_AUTHENTICATION**: Specify the SMTP authentication method. Defaults to ':login' if SMTP_USER is set.

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
docker pull sameersbn/redmine:2.5.2
```

**Step 4**: Migrate the database.

```
docker run --name redmine -i -t --rm [OPTIONS] sameersbn/redmine:2.5.2 app:db:migrate
```

**Step 5**: Start the image

```
docker run --name redmine -i -d [OPTIONS] sameersbn/redmine:2.5.2
```

## References
  * http://www.redmine.org/
  * http://www.redmine.org/projects/redmine/wiki/Guide
  * http://www.redmine.org/projects/redmine/wiki/RedmineInstall
