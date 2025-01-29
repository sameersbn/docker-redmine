# Changelog

**6.0.3**
- redmine: upgrade to v6.0.3

**6.0.2**
- redmine: upgrade to v6.0.2

**6.0.1-2**
- Fix `REDMINE_RELATIVE_URL_ROOT` for puma #570

**6.0.1-1**
- Replace unicorn application server with puma #569

**6.0.1**
- redmine: upgrade to v6.0.1
- `make test-release` now creates certificates for ssl

**5.1.4**
- redmine: upgrade to v5.1.4

**5.1.3**
- redmine: upgrade to v5.1.3

**5.1.2-1**
- Fix SMTP_SSL configuration #545
- Fix tx isolation detection for mysql #550
- Add logger level config support #551
- Fix imap cronjob [#553](https://github.com/sameersbn/docker-redmine/issues/553)
- Update rake documentation [#553](https://github.com/sameersbn/docker-redmine/issues/553)

**5.1.2**
- redmine: upgrade to v5.1.2
- Remove bundler version pin

**5.1.1-5**
- Only update file-permissions when needed on server start #547

**5.1.1-4**
- Switch to Ruby 3.2
- Replace ubuntu as base image with ruby:3.2-slim-bookworm
- Remove DB_SSL_MODE from mysql and mariadb example docker-compose files as mariadb does not support it

**5.1.1-3**
- Add SMTP_SSL option #513

**5.1.1-2**
- Instead of settings transaction isolation level, check and print a warning if it is not set to READ-COMMITTED. #531
- Update mysql/mariadb docker compose examples to set transaction isolation level to READ-COMMITTED. #531

**5.1.1-1**
- Update to ubuntu:focal-20231211
- Fix mysql signing key
- Pin bundler version to 2.4.22, as newer versions are not compatible with ruby 2.7

**5.1.1**

- redmine upgrade to v5.1.1
- Set transaction isolation level for mysql to fix race condition
https://www.redmine.org/projects/redmine/wiki/MySQL_configuration
- Fix fetch commits cron job #526

**5.1.0**

- redmine upgrade to v5.1.0
- Update to ubuntu-focal-20231003
- Upgrade unicorn gem from 5.x to 6.x
- Upgrade dalli gem from 2.x to 3.2.x

**5.0.6**

- redmine upgrade to v5.0.6
- Update to ubuntu-focal-20230801

**5.0.5**

- redmine: upgrade to v5.0.5
- Update to ubuntu:focal-20230301

**5.0.4**

- redmine: upgrade to v5.0.4
- Update to ubuntu:focal-20221019 for Text4Shell CVE

**5.0.3-1**

- Actually update to ubuntu:focal-20220826
- nginx: Update ssl config to disable TLSv1.0/1.1 and enable TLSv1.2/1.3
- nginx: Set expires on static files and enable gzip

**5.0.3**

- redmine: upgrade to v5.0.3
- Update to ubuntu:focal-20220826

**5.0.2**

- redmine: upgrade to v5.0.2

**5.0.1**

- redmine: upgrade to v5.0.1

**5.0.0-1**

- Add docker-compose-memcached.yml example
- Switch cache_store from dalli_store to mem_cache_store, issue [#501](https://github.com/sameersbn/docker-redmine/issues/501)

**5.0.0**

- redmine: upgrade to v5.0.0

**4.2.5**

- redmine: upgrade to v4.2.5
- Update to ubuntu:focal-20220316

**4.2.4**

- redmine: upgrade to v4.2.4
- Update to Ruby 2.7.5, issue [#488](https://github.com/sameersbn/docker-redmine/issues/488)
- Update to ubuntu focal-20220105 base image for sure this time...

**4.2.3-2**

- Revert to Ruby 2.6.3, issue [#488](https://github.com/sameersbn/docker-redmine/issues/488)

**4.2.3-1**

- Update to ubuntu focal-20220105 base image
- Update to Ruby 2.7.5
- Update gpg key for mysql

**4.2.3**

- redmine: upgrade to v4.2.3

**4.2.2-1**

- Silence supervisord run as root warning
- Add DB_SSL_MODE option for both postgresql and mysql

**4.2.2**

- redmine: upgrade to v4.2.2

**4.2.1-1**

- Fix keyserver #470
- Update to ubuntu focal-20210609 base image

**4.2.1**

- redmine: upgrade to v4.2.1

**4.2.0-1**

- Fixed mysql-client version to 5.7, issue #463

**4.2.0**

- redmine: upgrade to v4.2.0

**4.1.2**

- redmine: upgrade to v4.1.2
- use `ubuntu:focal-20210217` as docker base image
- update system packages

**4.1.1-9**

- Upgrade to Ruby 2.6 as 2.4,2.5 are EOL

**4.1.1-8**

- Add DB_SKIP_CHECK (#445)
- Run database check as redmine user (#445)

**4.1.1-7**

- Add REDMINE_RMAGICK_FONT_PATH parameter for Redmine 3.4 (#439)
- Rename REDMINE_RMAGICK_FONT_PATH to REDMINE_MINIMAGICK_FONT_PATH for Redmine 4.1 (#443)

**4.1.1-6**

- Fix typo for saving IMAGE_VERSION, issue #435

**4.1.1-5**

- Fix sqlite image migration from older versions, issue #431

**4.1.1-4**

- Add sqlite support, issue #350

**4.1.1-3**

- Ensure cron uses same timezone as rest of redmine, issue #257

**4.1.1-2**

- Update ImageMagick policy to allow PDF read for thumbnail generation. (#421)

**4.1.1-1**

- Install ghostscript to enable ImageMagick PDF support #420
- Fix bundler deprecation warnings #417

**4.1.1**

- redmine: upgrade to v4.1.1

**4.1.0**

- redmine: upgrade to v4.1.0

**4.0.5**

- redmine: upgrade to v4.0.5
- Fix "CRIT Server 'unix_http_server' running without any HTTP authentication checking"

**4.0.4**

- redmine: upgrade to v4.0.4

**4.0.3-2**

- Fix logrotate. Issue #402

**4.0.3-1**

- Update xenial to 20190222. PR: #397

**4.0.3**

- redmine: upgrade to v4.0.3

**4.0.2**

- redmine: upgrade to v4.0.2

**4.0.1**

- redmine: upgrade to v4.0.1

**4.0.0-3**

- Fix unicorn crash by avoiding version 5.5.0, Issue #292

**4.0.0-2**

- Improve cipher suite, based on Mozilla's TLS recommendations. Issue #226
- Fix to avoid adding double "secure" flags for cookies. Issue #297

**4.0.0-1**

- Fix REDMINE_FETCH_COMMITS for redmine 4.x

**4.0.0**

- redmine: upgrade to v.4.0.0
- Fix function tmp:sessions:clear
- Update ruby to v2.4
- Support single quotes in yaml to fix issue #378

**3.4.7-1**

- Fix app:backup:create by installing latest postgresql-client. Issue #364

**3.4.7**

- redmine: upgrade to v3.4.7
- Update mysql image
- Update memcache image
- Update postgresql image
- switch to `ubuntu:trusty-20180712` base image
- renamed `REDMINE_CACHE_DIR` to `REDMINE_ASSETS_DIR`, `REDMINE_BUILD_DIR` to `REDMINE_BUILD_ASSETS_DIR`, `REDMINE_RUNTIME_DIR` to `REDMINE_RUNTIME_ASSETS_DIR`
- upgrade to `ubuntu:xenial-20180705`
- Add: IMAP configuration parameter PROJECT_FROM_SUBADRESS
- Fix mysql version in docker-compose-mysql.yml
- Comment out pam_loginuid.so so cron jobs work

**3.4.6**

- redmine: upgrade to v3.4.6

**3.4.5**

- redmine: upgrade to v.3.4.5

**3.4.4-3**

- Added commands to install plugins/themes on running docker
- Only config ssl and starttls if configured as true. Fixes issue #318
- functions: Fix no error message when mysql database can't be contacted
- functions: Update tar commands to auto-detect compression

**3.4.4-2**

- Undo accidental change to REDMINE_VERSION

**3.4.4-1**

- nginx: Fix REDMINE_RELATIVE_URL_ROOT #324

**3.4.4**

- redmine: upgrade to v.3.4.4

**3.4.3**

- Add docker-compose-mysql.yml
- Fixes REDMINE_RELATIVE_URL_ROOT breaks nginx handling files #240
- redmine: upgrade to v.3.4.3

**3.4.2**

- redmine: upgrade to v.3.4.2

**3.4.1**

- redmine: upgrade to v.3.4.1

**3.4.0**

- redmine: upgrade to v.3.4.0

**3.3.4**

- added `IMAP_STARTTLS`, `IMAP_FOLDER`, `IMAP_MOVE_ON_SUCCESS`, `IMAP_MOVE_ON_FAILURE` configuration parameters
- upgrade to ruby2.3
- redmine: upgrade to v.3.3.4

**3.3.0**

- redmine: upgrade to v.3.3.0

**3.2.3**

- redmine: upgrade to v.3.2.3

**3.2.2**

- redmine: upgrade to v.3.2.2

**3.2.1**

- redmine: upgrade to v.3.2.1

**3.2.0-3**

- `DB_TYPE` parameter renamed to `DB_ADAPTER` with `mysql2` and `postgresql` as accepted values.
- exposed `DB_ENCODING` parameter
- complete rewrite
- renamed config `CA_CERTIFICATES_PATH` to `SSL_CA_CERTIFICATES_PATH`
- renamed config `REDMINE_HTTPS_HSTS_ENABLED` to `NGINX_HSTS_ENABLED`
- renamed config `REDMINE_HTTPS_HSTS_MAXAGE` to `NGINX_HSTS_MAXAGE`
- install `darcs`
- expose `REDMINE_ATTACHMENTS_DIR` parameter
- expose `REDMINE_SECRET_TOKEN` parameter
- expose `REDMINE_SUDO_MODE_ENABLED` and `REDMINE_SUDO_MODE_TIMEOUT` parameters
- expose `REDMINE_CONCURRENT_UPLOADS` parameter
- added `NGINX_ENABLED` parameter to disable the Nginx server
- feature: create backups
- feature: restore backups
- added `REDMINE_BACKUP_EXPIRY` option
- feature: automatic backups
- renamed parameter `REDMINE_BACKUPS` to `REDMINE_BACKUP_SCHEDULE`

**3.2.0**

- redmine: upgrade to v.3.2.0

**3.1.3**

- redmine: upgrade to v.3.1.3

**3.1.2**

- redmine: upgrade to v.3.1.2

**3.1.1**

- renamed `plugins/init` script to `plugins/post-install.sh`
- added `plugins/pre-install.sh` script to execute commands before plugin installation
- redmine: upgrade to v.3.1.1

**3.1.0-2**

- added support for receiving emails via IMAP

**3.1.0**

- redmine: upgrade to v.3.1.0

**3.0.4**

- added `SMTP_TLS` configuration parameter
- redmine: upgrade to v.3.0.4

**3.0.3-1**

- install: fix typo in `bundle install` command :facepalm:
- base image update to fix SSL vulnerability

**3.0.3**

- redmine: upgrade to v.3.0.3

**3.0.2**

- redmine: upgrade to v.3.0.2

**3.0.1**

- fix: avoid duplicate cron entries for 'Repository.fetch_changesets'
- fix: update the path of 'script/rails' script to 'bin/rails' in v.3.0.0
- redmine: upgrade to v.3.0.1

**3.0.0**

- redmine: upgrade to v.3.0.0

**2.6.2**

- update postgresql client to the latest version
- redmine: upgrade to v.2.6.2

**2.6.1**

- added `NGINX_WORKERS` configuration option
- enable IPv6 support
- added `SSL_VERIFY_CLIENT` configuration option
- redmine: upgrade to v.2.6.1

**2.6.0-1**

- fix: create the `${DATA_DIR}/tmp/` directory at startup

**2.6.0**

- redmine: upgrade to v.2.6.0

**2.5.3**

- redmine: upgrade to v.2.5.3
- added SMTP_OPENSSL_VERIFY_MODE configuration option
- feature: redmine logs volume
- autostart all daemons when supervisord is started
- removed internal mysql server
- added support for fetching `DB_NAME`, `DB_USER` and `DB_PASS` from the postgresql linkage
- added support for fetching `DB_NAME`, `DB_USER` and `DB_PASS` from the mysql linkage
- keep development and build packages

**2.5.2-3**

- upgrade to sameersbn/debian:jessie.20141001
- added REDMINE_HTTPS_HSTS_ENABLED configuration option (advanced config)
- added REDMINE_HTTPS_HSTS_MAXAGE configuration option (advanced config)
- shutdown container gracefully
- use sameersbn/debian:jessie.20140918 base image
- added REDMINE_FETCH_COMMITS configuration option
- added support for external/linked memcached servers
- removed internal memcached server
- run a daily cron job to fetch commits
- fix: run nginx workers as redmine user

**2.5.2-2**

- added system for users to install themes
- removed pre-installed themes
- added system for users to install plugins
- removed app:db:migrate command
- removed pre-installed plugins

**2.5.2-1**

- added app:rake command to execute rake commands
- added REDMINE_PORT configuration option
- enabled SPDY support
- added NGINX_X_FORWARDED_PROTO configuration option
- added REDMINE_HTTPS and associated configuration options
- upgrade to nginx-1.6.x series from the nginx/stable ppa
- update to sameersbn/ubuntu:14.04.20140628 image
- added new SMTP_ENABLED configuration option. Fixes #30
- moved data volume path to /home/redmine/data
- added REDMINE_RELATIVE_URL_ROOT configuration option (thanks to @k-kagurazaka)
- update to the sameersbn/ubuntu:12.04.20140812 baseimage
- automatically migrate the database when the redmine version changes

**2.5.2**

- switch to ruby1.2
- upgrade to redmine 2.5.2
- upgrade redmine_agile plugin to version 1.3.2
- update to sameersbn/ubuntu:12.04.20140628
- do not start openssh-server anymore, use nsenter to get shell access
- added nginx to proxy requests to unicorn
- upgrade redmine_contacts to version 3.2.17
- added SMTP_AUTHENTICATION configuration option
- added UNICORN_TIMEOUT configuration option
- added UNICORN_WORKERS configuration option
- replaced apache+passenger with unicorn app server
- added redmine_contacts plugin version 3.2.16
- upgrade redmine_agile plugin to version 1.3.1

**2.5.1**

- upgrade redmine_agile plugin to version 1.3.0
- upgrade redmine_agile plugin to version 1.2.0
- use sameersbn/ubuntu as the base docker image
- upgrade redmine_people plugin to version 0.1.8
- use redmine announcements version 1.3
- use redmine tags version 2.1.0
- support linking to mysql and postgresql containers
- added postgresql server support
- upgrade to redmine_agile v1.1.2
- added SMTP_STARTTLS config option
- added SMTP_DOMAIN config option
- updated gems cache
- install ruby1.9.1 from ubuntu repos
- added redmine dashboard plugin
- added redmine agile plugin
- repo reorganization

**v.2.5.0**

- upgrade to redmine-2.5.0
- added new circle theme
- update recurring_tasks plugin to v1.3.0
- update redmine_tags plugin
- update redmine_gist plugin

**v2.4.4**

- upgrade to redmine-2.4.4
- do not perform system upgrades (http://crosbymichael.com/dockerfile-best-practices-take-2.html)
- added memcache support
- restructured README with TOC
- added Changelog
- added DB_PORT configuration option
- update system packages

**v2.4.3**

- upgraded to redmine-2.4.3
- generate random root password
