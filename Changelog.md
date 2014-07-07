# Changelog

**latest**
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

