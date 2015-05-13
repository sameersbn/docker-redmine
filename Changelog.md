# Changelog

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

