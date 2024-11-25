#!/bin/bash
set -e

GEM_CACHE_DIR="${REDMINE_BUILD_ASSETS_DIR}/cache"

BUILD_DEPENDENCIES="curl libcurl4-openssl-dev libssl-dev libmagickcore-dev libmagickwand-dev \
                    libpq-dev libxslt1-dev libffi-dev libyaml-dev \
                    "

## Execute a command as REDMINE_USER
exec_as_redmine() {
  sudo -HEu ${REDMINE_USER} "$@"
}

# install build dependencies
apt-get update
apt-mark manual '.*' # Mark all packages installed manually so they are not removed when build dependencies are removed
DEBIAN_FRONTEND=noninteractive apt-get install -y ${BUILD_DEPENDENCIES}

# add ${REDMINE_USER} user
adduser --disabled-login --gecos 'Redmine' ${REDMINE_USER}
passwd -d ${REDMINE_USER}

# set PATH for ${REDMINE_USER} cron jobs
# Set GEM_HOME and BUNDLE_APP_CONFIG for ${REDMINE_USER}, needed for ruby:3.2-slim-bookworm image
cat > /tmp/cron.${REDMINE_USER} <<EOF
REDMINE_USER=${REDMINE_USER}
REDMINE_INSTALL_DIR=${REDMINE_INSTALL_DIR}
REDMINE_DATA_DIR=${REDMINE_DATA_DIR}
REDMINE_RUNTIME_ASSETS_DIR=${REDMINE_RUNTIME_ASSETS_DIR}
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
BUNDLE_APP_CONFIG=/usr/local/bundle
GEM_HOME=/usr/local/bundle
EOF
crontab -u ${REDMINE_USER} /tmp/cron.${REDMINE_USER}
rm -rf /tmp/cron.${REDMINE_USER}

# install redmine, use local copy if available
exec_as_redmine mkdir -p ${REDMINE_INSTALL_DIR}
if [[ -f ${REDMINE_BUILD_ASSETS_DIR}/redmine-${REDMINE_VERSION}.tar.gz ]]; then
  exec_as_redmine tar -zvxf ${REDMINE_BUILD_ASSETS_DIR}/redmine-${REDMINE_VERSION}.tar.gz --strip=1 -C ${REDMINE_INSTALL_DIR}
else
  echo "Downloading Redmine ${REDMINE_VERSION}..."
  exec_as_redmine curl -fL "http://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz" -o /tmp/redmine-${REDMINE_VERSION}.tar.gz

  echo "Extracting..."
  exec_as_redmine tar -zxf /tmp/redmine-${REDMINE_VERSION}.tar.gz --strip=1 -C ${REDMINE_INSTALL_DIR}

  exec_as_redmine rm -rf /tmp/redmine-${REDMINE_VERSION}.tar.gz
fi

# HACK: we want both the pg and mysql2 gems installed, so we remove the
#       respective lines and add them at the end of the Gemfile so that they
#       are both installed.
PG_GEM=$(grep 'gem .pg.' ${REDMINE_INSTALL_DIR}/Gemfile | awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}')
MYSQL2_GEM=$(grep 'gem .mysql2.' ${REDMINE_INSTALL_DIR}/Gemfile | awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}')
# SQLITE line spans 2 lines until after this commit: https://github.com/redmine/redmine/commit/dc05c52e5a25b43c49246a952607551bf0d96f29#diff-8b7db4d5cc4b8f6dc8feb7030baa2478
# The 2 lines one has RUBY_VERSION in it
SQLITE3_2LINES_GEM=$(grep -A1 -e 'gem .sqlite3..*RUBY_VERSION' "${REDMINE_INSTALL_DIR}/Gemfile" | awk '{gsub(/^[ \t ]+|[ \t ]+$/,    ""); print;}')
SQLITE3_GEM=$(grep 'gem .sqlite3.' "${REDMINE_INSTALL_DIR}/Gemfile" | awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}')

[ -z "$PG_GEM" ] && (echo "Error couldn't find gem pg, update instal.sh"; exit 1)
[ -z "$MYSQL2_GEM" ] && (echo "Error couldn't find gem mysql2, update instal.sh"; exit 1)
[ -z "$SQLITE3_GEM" ] && (echo "Error couldn't find gem sqlite3, update instal.sh"; exit 1)

sed -i \
  -e '/gem .pg./d' \
  -e '/gem .mysql2./d' \
  ${REDMINE_INSTALL_DIR}/Gemfile

if [ -z "$SQLITE3_2LINES_GEM" ]
then
  sed -i \
    -e '/gem .sqlite3./d' \
    "${REDMINE_INSTALL_DIR}/Gemfile"
else
  # Delete 2 lines
  sed -i \
    -e '/gem .sqlite3./ { N; d; }' \
    "${REDMINE_INSTALL_DIR}/Gemfile"
  SQLITE3_GEM=${SQLITE3_2LINES_GEM}
fi

# Delete test: puma
sed -i \
  -e '/gem .puma./d' \
  "${REDMINE_INSTALL_DIR}/Gemfile"

(
  echo "${PG_GEM}";
  echo "${MYSQL2_GEM}";
  echo "${SQLITE3_GEM}";
  echo 'gem "puma", "~> 6"';
  echo 'gem "dalli", "~> 3.2.6"';
) >> ${REDMINE_INSTALL_DIR}/Gemfile

## some gems complain about missing database.yml, shut them up!
exec_as_redmine cp ${REDMINE_INSTALL_DIR}/config/database.yml.example ${REDMINE_INSTALL_DIR}/config/database.yml

# install gems
cd ${REDMINE_INSTALL_DIR}

## use local cache if available
if [[ -d ${GEM_CACHE_DIR} ]]; then
  cp -a ${GEM_CACHE_DIR} ${REDMINE_INSTALL_DIR}/vendor/cache
  chown -R ${REDMINE_USER}: ${REDMINE_INSTALL_DIR}/vendor/cache
fi
exec_as_redmine bundle config set path "${REDMINE_INSTALL_DIR}/vendor/bundle"
exec_as_redmine bundle config set without development test
exec_as_redmine bundle install -j$(nproc)

# finalize redmine installation
exec_as_redmine mkdir -p ${REDMINE_INSTALL_DIR}/tmp ${REDMINE_INSTALL_DIR}/tmp/pdf ${REDMINE_INSTALL_DIR}/tmp/pids ${REDMINE_INSTALL_DIR}/tmp/sockets

# create link public/plugin_assets directory
rm -rf ${REDMINE_INSTALL_DIR}/public/plugin_assets
exec_as_redmine ln -sf ${REDMINE_DATA_DIR}/tmp/plugin_assets ${REDMINE_INSTALL_DIR}/public/plugin_assets

# create link tmp/thumbnails directory
rm -rf ${REDMINE_INSTALL_DIR}/tmp/thumbnails
exec_as_redmine ln -sf ${REDMINE_DATA_DIR}/tmp/thumbnails ${REDMINE_INSTALL_DIR}/tmp/thumbnails

# symlink log -> ${REDMINE_LOG_DIR}/redmine
rm -rf ${REDMINE_INSTALL_DIR}/log
exec_as_redmine ln -sf ${REDMINE_LOG_DIR}/redmine ${REDMINE_INSTALL_DIR}/log

# disable default nginx configuration
rm -f /etc/nginx/sites-enabled/default

# run nginx as ${REDMINE_USER} user
sed -i "s|user www-data|user ${REDMINE_USER}|" /etc/nginx/nginx.conf

# move supervisord.log file to ${REDMINE_LOG_DIR}/supervisor/
sed -i "s|^logfile=.*|logfile=${REDMINE_LOG_DIR}/supervisor/supervisord.log ;|" /etc/supervisor/supervisord.conf

# move nginx logs to ${REDMINE_LOG_DIR}/nginx
sed -i \
  -e "s|access_log /var/log/nginx/access.log;|access_log ${REDMINE_LOG_DIR}/nginx/access.log;|" \
  -e "s|error_log /var/log/nginx/error.log;|error_log ${REDMINE_LOG_DIR}/nginx/error.log;|" \
  /etc/nginx/nginx.conf

# Set log rotate to use root:utmp to match permissions in /var/log
# Fixes issue #402
sed -i 's|su root syslog|su root utmp|' /etc/logrotate.conf

# setup log rotation for redmine application logs
cat > /etc/logrotate.d/redmine <<EOF
${REDMINE_LOG_DIR}/redmine/*.log {
  su root redmine
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  copytruncate
}
EOF

# setup log rotation for redmine vhost logs
cat > /etc/logrotate.d/redmine-vhost <<EOF
${REDMINE_LOG_DIR}/nginx/*.log {
  su redmine redmine
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  copytruncate
}
EOF

# configure supervisord log rotation
cat > /etc/logrotate.d/supervisord <<EOF
${REDMINE_LOG_DIR}/supervisor/*.log {
  su root redmine
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  copytruncate
}
EOF

# configure supervisord to start nginx
cat > /etc/supervisor/conf.d/nginx.conf <<EOF
[program:nginx]
priority=20
directory=/tmp
command=/usr/sbin/nginx -g "daemon off;"
user=root
autostart={{NGINX_ENABLED}}
autorestart=true
stdout_logfile=${REDMINE_LOG_DIR}/supervisor/%(program_name)s.log
stderr_logfile=${REDMINE_LOG_DIR}/supervisor/%(program_name)s.log
EOF

# configure supervisord to start puma
cat > /etc/supervisor/conf.d/puma.conf <<EOF
[program:puma]
priority=10
directory=${REDMINE_INSTALL_DIR}
environment=HOME=${REDMINE_HOME}
command=bundle exec puma -e ${RAILS_ENV} -C ${REDMINE_INSTALL_DIR}/config/puma.rb
user=${REDMINE_USER}
autostart=true
autorestart=true
stopsignal=QUIT
stdout_logfile=${REDMINE_LOG_DIR}/supervisor/%(program_name)s.log
stderr_logfile=${REDMINE_LOG_DIR}/supervisor/%(program_name)s.log
EOF

# configure supervisord to start crond
cat > /etc/supervisor/conf.d/cron.conf <<EOF
[program:cron]
priority=20
directory=/tmp
command=/usr/sbin/cron -f
user=root
autostart=true
autorestart=true
stdout_logfile=${REDMINE_LOG_DIR}/supervisor/%(program_name)s.log
stderr_logfile=${REDMINE_LOG_DIR}/supervisor/%(program_name)s.log
EOF

# silence "CRIT Server 'unix_http_server' running without any HTTP authentication checking" message
# https://github.com/Supervisor/supervisor/issues/717
sed -i '/\.sock/a password=dummy' /etc/supervisor/supervisord.conf
sed -i '/\.sock/a username=dummy' /etc/supervisor/supervisord.conf
# silence "CRIT Supervisor is running as root." message
sed -i '/\[supervisord\]/a user=root' /etc/supervisor/supervisord.conf

# update ImageMagick policy to allow PDF read for thumbnail generation.
# https://github.com/sameersbn/docker-redmine/pull/421
sed -i 's/ domain="coder" rights="none" pattern="PDF" / domain="coder" rights="read" pattern="PDF" /g' /etc/ImageMagick-*/policy.xml

# purge build dependencies and cleanup apt
apt-get purge -y --auto-remove ${BUILD_DEPENDENCIES}
rm -rf /var/lib/apt/lists/*
