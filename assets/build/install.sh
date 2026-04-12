#!/bin/bash
set -e

GEM_CACHE_DIR="${REDMINE_BUILD_ASSETS_DIR}/cache"
REDMINE_CACHE_DIR="/var/cache/redmine"

BUILD_DEPENDENCIES="libcurl4-openssl-dev libssl-dev libmagickcore-dev libmagickwand-dev \
                    libpq-dev libxslt1-dev libffi-dev libyaml-dev freetds-dev \
                    "

## Execute a command as REDMINE_USER
exec_as_redmine() {
  sudo -HEu ${REDMINE_USER} "$@"
}

case "${REDMINE_FLAVOR:-redmine}" in
  redmine)
    REDMINE_DIST_NAME="Redmine"
    REDMINE_ARCHIVE_BASENAME="redmine-${REDMINE_VERSION}"
    REDMINE_DOWNLOAD_URL="https://www.redmine.org/releases/${REDMINE_ARCHIVE_BASENAME}.tar.gz"
    ;;
  redmica)
    REDMINE_DIST_NAME="Redmica"
    REDMINE_ARCHIVE_BASENAME="redmica-${REDMINE_VERSION}"
    REDMINE_DOWNLOAD_URL="https://github.com/redmica/redmica/archive/refs/tags/v${REDMINE_VERSION}.tar.gz"
    ;;
  *)
    echo "Unsupported REDMINE_FLAVOR: ${REDMINE_FLAVOR}. Expected one of: redmine, redmica" >&2
    exit 1
    ;;
esac

REDMINE_ARCHIVE_PATH="${REDMINE_CACHE_DIR}/${REDMINE_ARCHIVE_BASENAME}.tar.gz"

# install build dependencies
apt-get update
apt-mark manual '.*' > /dev/null # Mark all packages installed manually so they are not removed when build dependencies are removed
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
ls ${REDMINE_CACHE_DIR}
if [[ ! -f ${REDMINE_ARCHIVE_PATH} ]]; then
  echo "Downloading ${REDMINE_DIST_NAME} ${REDMINE_VERSION}..."
  curl -fL "${REDMINE_DOWNLOAD_URL}" -o ${REDMINE_ARCHIVE_PATH}
fi
echo "Extracting..."
exec_as_redmine tar -zxf ${REDMINE_ARCHIVE_PATH} --strip=1 -C ${REDMINE_INSTALL_DIR}
exec_as_redmine rm -f ${REDMINE_INSTALL_DIR}/files/delete.me ${REDMINE_INSTALL_DIR}/log/delete.me

# Normalize runtime gems at build time.
# Re-add puma and related runtime gems explicitly so they remain available
# for the production nginx + puma runtime managed by supervisor, even if
# the upstream Gemfile changes grouping or declaration style.
sed -i \
  -e '/gem .puma./d' \
  "${REDMINE_INSTALL_DIR}/Gemfile"

(
  echo 'gem "puma", "~> 6"';
  echo 'gem "dalli", "~> 3.2.6"';
) >> ${REDMINE_INSTALL_DIR}/Gemfile

## Avoid brittle Gemfile surgery during build.
## Resolve DB adapter gems via a temporary config/database.yml so bundler
## can see the intended adapters during bundle install.
cat > ${REDMINE_INSTALL_DIR}/config/database.yml <<EOF
mysql2:
  adapter: mysql2

postgresql:
  adapter: postgresql

sqlite3:
  adapter: sqlite3
  database: tmp/bundler.sqlite3
EOF
chown ${REDMINE_USER}: ${REDMINE_INSTALL_DIR}/config/database.yml

# install gems
cd ${REDMINE_INSTALL_DIR}

## use local cache if available
if [[ -d ${GEM_CACHE_DIR} ]]; then
  cp -a ${GEM_CACHE_DIR} ${REDMINE_INSTALL_DIR}/vendor/cache
  chown -R ${REDMINE_USER}: ${REDMINE_INSTALL_DIR}/vendor/cache
fi
exec_as_redmine bundle config set path "${REDMINE_INSTALL_DIR}/vendor/bundle"
exec_as_redmine bundle config set without development test

# Prefer system libxml2/libxslt for nokogiri to improve native build stability.
exec_as_redmine bundle config set build.nokogiri --use-system-libraries

exec_as_redmine bundle install -j$(nproc)
rm -f ${REDMINE_INSTALL_DIR}/config/database.yml

# finalize redmine installation
exec_as_redmine mkdir -p ${REDMINE_INSTALL_DIR}/tmp ${REDMINE_INSTALL_DIR}/tmp/pdf ${REDMINE_INSTALL_DIR}/tmp/pids ${REDMINE_INSTALL_DIR}/tmp/sockets

# create link public/plugin_assets directory
rm -rf ${REDMINE_INSTALL_DIR}/public/assets/plugin_assets
exec_as_redmine mkdir -p ${REDMINE_INSTALL_DIR}/public/assets
exec_as_redmine ln -sf ${REDMINE_DATA_DIR}/tmp/plugin_assets ${REDMINE_INSTALL_DIR}/public/assets/plugin_assets

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
rm -rf ${REDMINE_HOME}/.bundle/cache/*
rm -rf ${REDMINE_INSTALL_DIR}/vendor/bundle/ruby/*/cache/*
