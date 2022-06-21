FROM ubuntu:focal-20220316 AS add-apt-repositories

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y wget gnupg2 \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu focal main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6 \
 && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu focal main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu focal main" >> /etc/apt/sources.list \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv 467B942D3A79BD29 \
 && echo "deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-5.7" >> /etc/apt/sources.list

FROM ubuntu:focal-20220316

LABEL maintainer="sameer@damagehead.com"

ENV RUBY_VERSION=2.7 \
    REDMINE_VERSION=5.0.2 \
    REDMINE_USER="redmine" \
    REDMINE_HOME="/home/redmine" \
    REDMINE_LOG_DIR="/var/log/redmine" \
    REDMINE_ASSETS_DIR="/etc/docker-redmine" \
    RAILS_ENV=production

ENV REDMINE_INSTALL_DIR="${REDMINE_HOME}/redmine" \
    REDMINE_DATA_DIR="${REDMINE_HOME}/data" \
    REDMINE_BUILD_ASSETS_DIR="${REDMINE_ASSETS_DIR}/build" \
    REDMINE_RUNTIME_ASSETS_DIR="${REDMINE_ASSETS_DIR}/runtime"

COPY --from=add-apt-repositories /etc/apt/trusted.gpg /etc/apt/trusted.gpg

COPY --from=add-apt-repositories /etc/apt/sources.list /etc/apt/sources.list
COPY --from=add-apt-repositories /etc/apt/sources.list.d/pgdg.list /etc/apt/sources.list.d/

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      supervisor logrotate nginx mysql-client=5.7.* postgresql-client ca-certificates sudo tzdata \
      imagemagick subversion git cvs bzr mercurial darcs rsync ruby${RUBY_VERSION} locales openssh-client \
      gcc g++ make patch pkg-config gettext-base ruby${RUBY_VERSION}-dev libc6-dev zlib1g-dev libxml2-dev \
      libmysqlclient21 libpq5 libyaml-0-2 libcurl4 libssl1.1 uuid-dev xz-utils \
      libxslt1.1 libffi7 zlib1g gsfonts vim-tiny ghostscript sqlite3 libsqlite3-dev \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && gem install --no-document bundler \
 && rm -rf /var/lib/apt/lists/*

COPY assets/build/ ${REDMINE_BUILD_ASSETS_DIR}/

RUN bash ${REDMINE_BUILD_ASSETS_DIR}/install.sh

COPY assets/runtime/ ${REDMINE_RUNTIME_ASSETS_DIR}/

COPY assets/tools/ /usr/bin/

COPY entrypoint.sh /sbin/entrypoint.sh

COPY VERSION /VERSION

RUN chmod 755 /sbin/entrypoint.sh \
 && sed -i '/session    required     pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/cron

EXPOSE 80/tcp 443/tcp

WORKDIR ${REDMINE_INSTALL_DIR}

ENTRYPOINT ["/sbin/entrypoint.sh"]

CMD ["app:start"]
