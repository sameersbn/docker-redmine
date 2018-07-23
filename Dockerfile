FROM node:8.2-stretch
# RUN apt update && apt-get install redmine -y
ENV RUBY_VERSION=2.3 \
    REDMINE_VERSION=3.4.2 \
    REDMINE_USER="redmine" \
    REDMINE_HOME="/home/redmine" \
    REDMINE_LOG_DIR="/var/log/redmine" \
    REDMINE_CACHE_DIR="/etc/docker-redmine" \
    RAILS_ENV=production

ENV REDMINE_INSTALL_DIR="${REDMINE_HOME}/redmine" \
    REDMINE_DATA_DIR="${REDMINE_HOME}/data" \
    REDMINE_BUILD_DIR="${REDMINE_CACHE_DIR}/build" \
    REDMINE_RUNTIME_DIR="${REDMINE_CACHE_DIR}/runtime"

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor logrotate nginx mysql-client postgresql-client \
      imagemagick subversion git cvs bzr mercurial darcs rsync ruby${RUBY_VERSION} locales openssh-client \
      gcc g++ make patch pkg-config gettext-base ruby${RUBY_VERSION}-dev libc6-dev zlib1g-dev libxml2-dev \
      default-libmysqlclient-dev libpq5 libyaml-0-2 libcurl3 libssl1.1 uuid-dev xz-utils \
      libxslt1.1 libffi6 zlib1g gsfonts \
      libcurl4-openssl-dev libssl-dev libmagickcore-dev libmagickwand-dev \
      libpq-dev libxslt1-dev libffi-dev libyaml-dev sudo \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && gem install --no-document bundler \
 && rm -rf /var/lib/apt/lists/*

COPY assets/build/ ${REDMINE_BUILD_DIR}/
RUN bash ${REDMINE_BUILD_DIR}/install.sh

COPY assets/runtime/ ${REDMINE_RUNTIME_DIR}/
COPY assets/tools/ /usr/bin/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 80/tcp 443/tcp

VOLUME ["${REDMINE_DATA_DIR}", "${REDMINE_LOG_DIR}"]
WORKDIR ${REDMINE_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
