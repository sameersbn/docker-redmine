FROM ruby:3.3-slim-bookworm

LABEL maintainer="sameer@damagehead.com"

ENV REDMINE_VERSION=6.0.3 \
    REDMINE_USER="redmine" \
    REDMINE_HOME="/home/redmine" \
    REDMINE_LOG_DIR="/var/log/redmine" \
    REDMINE_ASSETS_DIR="/etc/docker-redmine" \
    RAILS_ENV=production

ENV REDMINE_INSTALL_DIR="${REDMINE_HOME}/redmine" \
    REDMINE_DATA_DIR="${REDMINE_HOME}/data" \
    REDMINE_BUILD_ASSETS_DIR="${REDMINE_ASSETS_DIR}/build" \
    REDMINE_RUNTIME_ASSETS_DIR="${REDMINE_ASSETS_DIR}/runtime"

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      supervisor logrotate nginx mariadb-client postgresql-client ca-certificates sudo tzdata \
      imagemagick subversion git cvs bzr mercurial darcs rsync locales openssh-client \
      gcc g++ make patch pkg-config gettext-base libc6-dev zlib1g-dev libxml2-dev \
      default-libmysqlclient-dev libmariadb-dev libpq5 libyaml-0-2 libcurl4 libssl3 uuid-dev xz-utils \
      libxslt1.1 libffi8 zlib1g gsfonts vim-tiny ghostscript sqlite3 libsqlite3-dev jq\
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
