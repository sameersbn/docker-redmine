# Table of Contents
- [Introduction](#introduction)
    - [Version](#version)
    - [Changelog](Changelog.md)
- [Reporting Issues](#reporting-issues)
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
Current Version: **2.5.2**

# Reporting Issues

Docker is a relatively new project and is active being developed and tested by a thriving community of developers and testers and every release of docker features many enhancements and bugfixes.

Given the nature of the development and release cycle it is very important that you have the latest version of docker installed because any issue that you encounter might have already been fixed with a newer docker release.

For ubuntu users I suggest [installing docker](https://docs.docker.com/installation/ubuntulinux/) using docker's own package repository since the version of docker packaged in the ubuntu repositories are a little dated.

Here is the shortform of the installation of an updated version of docker on ubuntu.

```bash
sudo apt-get purge docker.io
curl -s https://get.docker.io/ubuntu/ | sudo sh
sudo apt-get update
sudo apt-get install lxc-docker
```

Fedora and RHEL/CentOS users should try disabling selinux with `setenforce 0` and check if resolves the issue. If it does than there is not much that I can help you with. You can either stick with selinux disabled (not recommended by redhat) or switch to using ubuntu.

If using the latest docker version and/or disabling selinux does not fix the issue then please file a issue request on the [issues](https://github.com/sameersbn/docker-gitlab/issues) page.

In your issue report please make sure you provide the following information:

- The host ditribution and release version.
- Output of the `docker version` command
- Output of the `docker info` command
- The `docker run` command you used to run the image (mask out the sensitive bits).

# Installation

Pull the image from the docker index. This is the recommended method of installation as it is easier to update image in the future. These builds are performed by the Trusted Build service.

```bash
docker pull sameersbn/redmine:latest
```

Since version `2.4.2`, the image builds are being tagged. You can now pull a particular version of redmine by specifying the version number. For example,

```bash
docker pull sameersbn/redmine:2.5.2
```

Alternately you can build the image yourself.

```bash
git clone https://github.com/sameersbn/docker-redmine.git
cd docker-redmine
docker build --tag="$USER/redmine" .
```

# Quick Start

Run the redmine image with the name "redmine".

```bash
docker run --name=redmine -it --rm -p 10080:80 \
sameersbn/redmine:2.5.2
```

**NOTE**: Please allow a minute or two for the Redmine application to start.

Point your browser to `http://localhost:10080` and login using the default username and password:

* username: **admin**
* password: **admin**

You should now have the Redmine application up and ready for testing. If you want to use this image in production the please read on.

# Configuration

## Data Store

For the file storage we need to mount a volume at the following location.

* `/home/redmine/data`

> **NOTE**
>
> Existing users **need to move** the existing files directory inside `/opt/redmine/data/`.
>
> ```bash
> mkdir -p /opt/redmine/data
> mv /opt/redmine/files /opt/redmine/data
> ```

SELinux users are also required to change the security context of the mount point so that it plays nicely with selinux.

```bash
mkdir -p /opt/redmine/data
sudo chcon -Rt svirt_sandbox_file_t /opt/redmine/data
```

Volumes can be mounted in docker by specifying the **'-v'** option in the docker run command.

```bash
docker run --name=redmine -it --rm \
  -v /opt/redmine/data:/home/redmine/data sameersbn/redmine:2.5.2
```

## Database

Redmine uses a database backend to store its data.

### MySQL

#### Internal MySQL Server

> **Warning**
>
> The internal mysql server will soon be removed from the image.

> Please use a linked [mysql](#linking-to-mysql-container) or
> [postgresql](#linking-to-postgresql-container) container instead.
> Or else connect with an external [mysql](#external-mysql-server) or
> [postgresql](#external-postgresql-server) server.

> You've been warned.

This docker image is configured to use a MySQL database backend. The database connection can be configured using environment variables. If not specified, the image will start a mysql server internally and use it. However in this case, the data stored in the mysql database will be lost if the container is stopped/deleted. To avoid this you should mount a volume at `/var/lib/mysql`.

SELinux users are also required to change the security context of the mount point so that it plays nicely with selinux.

```bash
mkdir -p /opt/redmine/mysql
sudo chcon -Rt svirt_sandbox_file_t /opt/redmine/mysql
```

The updated run command looks like this.

```bash
docker run --name=redmine -it --rm \
  -v /opt/redmine/data:/home/redmine/data \
  -v /opt/redmine/mysql:/var/lib/mysql sameersbn/redmine:2.5.2
```

This will make sure that the data stored in the database is not lost when the image is stopped and started again.

#### External MySQL Server

The image can be configured to use an external MySQL database instead of starting a MySQL server internally. The database configuration should be specified using environment variables while starting the Redmine image.

Before you start the Redmine image create user and database for redmine.

```sql
mysql -uroot -p
CREATE USER 'redmine'@'%.%.%.%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS `redmine_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `redmine_production`.* TO 'redmine'@'%.%.%.%';
```

Now that we have the database created for redmine, lets install the database schema. This is done by starting the redmine container with the `app:db:migrate` command.

*Assuming that the mysql server host is 192.168.1.100*

```bash
docker run --name=redmine -it --rm \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=redmine_production" \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/data:/home/redmine/data sameersbn/redmine:2.5.2 app:db:migrate
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the redmine application.

```bash
docker run --name=redmine -it --rm \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=redmine_production" \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/data:/home/redmine/data sameersbn/redmine:2.5.2
```

This will initialize the redmine database and after a couple of minutes your redmine instance should be ready to use.

#### Linking to MySQL Container

You can link this image with a mysql container for the database requirements. The alias of the mysql server container should be set to **mysql** while linking with the redmine image.

If a mysql container is linked, only the `DB_TYPE`, `DB_HOST` and `DB_PORT` settings are automatically retrieved using the linkage. You may still need to set other database connection parameters such as the `DB_NAME`, `DB_USER`, `DB_PASS` and so on.

To illustrate linking with a mysql container, we will use the [sameersbn/mysql](https://github.com/sameersbn/docker-mysql) image. When using docker-mysql in production you should mount a volume for the mysql data store. Please refer the [README](https://github.com/sameersbn/docker-mysql/blob/master/README.md) of docker-mysql for details.

First, lets pull the mysql image from the docker index.

```bash
docker pull sameersbn/mysql:latest
```

For data persistence lets create a store for the mysql and start the container.

SELinux users are also required to change the security context of the mount point so that it plays nicely with selinux.

```bash
mkdir -p /opt/mysql/data
sudo chcon -Rt svirt_sandbox_file_t /opt/mysql/data
```

The updated run command looks like this.

```bash
docker run --name mysql -it --rm \
  -v /opt/mysql/data:/var/lib/mysql \
  sameersbn/mysql:latest
```

You should now have the mysql server running. By default the sameersbn/mysql image does not assign a password for the root user and allows remote connections for the root user from the `172.17.%.%` address space. This means you can login to the mysql server from the host as the root user.

Now, lets login to the mysql server and create a user and database for the redmine application.

```bash
docker run -it --rm sameersbn/mysql:latest mysql -uroot -h$(docker inspect --format {{.NetworkSettings.IPAddress}} mysql)
```

```sql
CREATE USER 'redmine'@'172.17.%.%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS `redmine_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `redmine_production`.* TO 'redmine'@'172.17.%.%';
FLUSH PRIVILEGES;
```

Now that we have the database created for redmine, lets install the database schema. This is done by starting the redmine container with the `app:db:migrate` command.

```bash
docker run --name=redmine -it --rm --link mysql:mysql \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "DB_NAME=redmine_production" \
  -v /opt/redmine/data:/home/redmine/data \
  sameersbn/redmine:2.5.2 app:db:migrate
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the redmine application.

```bash
docker run --name=redmine -it --rm --link mysql:mysql \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "DB_NAME=redmine_production" \
  -v /opt/redmine/data:/home/redmine/data \
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

Now that we have the database created for redmine, lets install the database schema. This is done by starting the redmine container with the `app:db:migrate` command.

*Assuming that the PostgreSQL server host is 192.168.1.100*

```bash
docker run --name=redmine -it --rm \
  -e "DB_TYPE=postgres" -e "DB_HOST=192.168.1.100" \
  -e "DB_NAME=redmine_production" -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/data:/home/redmine/data \
  sameersbn/redmine:2.5.2 app:db:migrate
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the redmine application.

```bash
docker run --name=redmine -it --rm \
  -e "DB_TYPE=postgres" -e "DB_HOST=192.168.1.100" \
  -e "DB_NAME=redmine_production" -e "DB_USER=redmine" -e "DB_PASS=password" \
  -v /opt/redmine/data:/home/redmine/data \
  sameersbn/redmine:2.5.2
```

This will initialize the redmine database and after a couple of minutes your redmine instance should be ready to use.

#### Linking to PostgreSQL Container

You can link this image with a postgresql container for the database requirements. The alias of the postgresql server container should be set to **postgresql** while linking with the redmine image.

If a postgresql container is linked, only the `DB_TYPE`, `DB_HOST` and `DB_PORT` settings are automatically retrieved using the linkage. You may still need to set other database connection parameters such as the `DB_NAME`, `DB_USER`, `DB_PASS` and so on.

To illustrate linking with a postgresql container, we will use the [sameersbn/postgresql](https://github.com/sameersbn/docker-postgresql) image. When using postgresql image in production you should mount a volume for the postgresql data store. Please refer the [README](https://github.com/sameersbn/docker-postgresql/blob/master/README.md) of docker-postgresql for details.

First, lets pull the postgresql image from the docker index.

```bash
docker pull sameersbn/postgresql:latest
```

For data persistence lets create a store for the postgresql and start the container.

SELinux users are also required to change the security context of the mount point so that it plays nicely with selinux.

```bash
mkdir -p /opt/postgresql/data
sudo chcon -Rt svirt_sandbox_file_t /opt/postgresql/data
```

The updated run command looks like this.

```bash
docker run --name postgresql -it --rm \
  -v /opt/postgresql/data:/var/lib/postgresql \
  sameersbn/postgresql:latest
```

You should now have the postgresql server running. The password for the postgres user can be found in the logs of the postgresql image.

```bash
docker logs postgresql
```

Now, lets login to the postgresql server and create a user and database for the redmine application.

```bash
docker run -it --rm sameersbn/postgresql:latest psql -U postgres -h $(docker inspect --format {{.NetworkSettings.IPAddress}} postgresql)
```

```sql
CREATE ROLE redmine with LOGIN CREATEDB PASSWORD 'password';
CREATE DATABASE redmine_production;
GRANT ALL PRIVILEGES ON DATABASE redmine_production to redmine;
```

Now that we have the database created for redmine, lets install the database schema. This is done by starting the redmine container with the `app:db:migrate` command.

```bash
docker run --name=redmine -it --rm --link postgresql:postgresql \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "DB_NAME=redmine_production" \
  -v /opt/redmine/data:/home/redmine/data \
  sameersbn/redmine:2.5.2 app:db:migrate
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the redmine application.

```bash
docker run --name=redmine -it --rm --link postgresql:postgresql \
  -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "DB_NAME=redmine_production" \
  -v /opt/redmine/data:/home/redmine/data \
  sameersbn/redmine:2.5.2
```

### Mail

The mail configuration should be specified using environment variables while starting the redmine image. The configuration defaults to using gmail to send emails and requires the specification of a valid username and password to login to the gmail servers.

The following environment variables need to be specified to get mail support to work.

* SMTP_ENABLED (defaults to `true` if `SMTP_USER` is defined, else defaults to `false`)
* SMTP_DOMAIN (defaults to `www.gmail.com`)
* SMTP_HOST (defaults to `smtp.gmail.com`)
* SMTP_PORT (defaults to `587`)
* SMTP_USER
* SMTP_PASS
* SMTP_STARTTLS (defaults to `true`)
* SMTP_AUTHENTICATION (defaults to `:login` if `SMTP_USER` is set)

```bash
docker run --name=redmine -it --rm \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  -v /opt/redmine/data:/home/redmine/data sameersbn/redmine:2.5.2
```

If you are not using google mail, then please configure the SMTP host and port using the `SMTP_HOST` and `SMTP_PORT` configuration parameters.

__NOTE:__

I have only tested standard gmail and google apps login. I expect that the currently provided configuration parameters should be sufficient for most users. If this is not the case, then please let me know.

### Putting it all together

```bash
docker run --name=redmine -d -h redmine.local.host \
  -v /opt/redmine/data:/home/redmine/data \
  -v /opt/redmine/mysql:/var/lib/mysql \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/redmine:2.5.2
```

If you are using an external mysql database

```bash
docker run --name=redmine -d -h redmine.local.host \
  -v /opt/redmine/data:/home/redmine/data \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=redmine_production" -e "DB_USER=redmine" -e "DB_PASS=password" \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/redmine:2.5.2
```

### Available Configuration Parameters

*Please refer the docker run command options for the `--env-file` flag where you can specify all required environment variables in a single file. This will save you from writing a potentially long docker run command.*

Below is the complete list of parameters that can be set using environment variables.

- **DB_TYPE**: The database type. Possible values: `mysql`, `postgres`. Defaults to `mysql`.
- **DB_HOST**: The database server hostname. Defaults to `localhost`.
- **DB_PORT**: The database server port. Defaults to `3306`.
- **DB_NAME**: The database name. Defaults to `redmine_production`
- **DB_USER**: The database user. Defaults to `root`
- **DB_PASS**: The database password. Defaults to no password
- **DB_POOL**: The database connection pool count. Defaults to `5`.
- **NGINX_MAX_UPLOAD_SIZE**: Maximum acceptable upload size. Defaults to `20m`.
- **UNICORN_WORKERS**: The number of unicorn workers to start. Defaults to `2`.
- **UNICORN_TIMEOUT**: Sets the timeout of unicorn worker processes. Defaults to `60` seconds.
- **MEMCACHED_SIZE**: The local memcached size in Mb. Defaults to `64`. Disabled if `0`.
- **SMTP_ENABLED**: Enable mail delivery via SMTP. Defaults to `true` if `SMTP_USER` is defined, else defaults to `false`.
- **SMTP_DOMAIN**: SMTP domain. Defaults to `www.gmail.com`
- **SMTP_HOST**: SMTP server host. Defaults to `smtp.gmail.com`
- **SMTP_PORT**: SMTP server port. Defaults to `587`.
- **SMTP_USER**: SMTP username.
- **SMTP_PASS**: SMTP password.
- **SMTP_STARTTLS**: Enable STARTTLS. Defaults to `true`.
- **SMTP_AUTHENTICATION**: Specify the SMTP authentication method. Defaults to `:login` if `SMTP_USER` is set.

## Upgrading

To upgrade to newer redmine releases, simply follow this 4 step upgrade procedure.

**Step 1**: Update the docker image.

```bash
docker pull sameersbn/redmine:2.5.2
```

**Step 2**: Stop and remove the currently running image

```bash
docker stop redmine
docker rm redmine
```

**Step 3**: Backup the database in case something goes wrong.

```bash
mysqldump -h <mysql-server-ip> -uredmine -p --add-drop-table redmine_production > redmine.sql
```

**Step 4**: Start the image

```bash
docker run --name=redmine -d [OPTIONS] sameersbn/redmine:2.5.2
```

## References
  * http://www.redmine.org/
  * http://www.redmine.org/projects/redmine/wiki/Guide
  * http://www.redmine.org/projects/redmine/wiki/RedmineInstall
