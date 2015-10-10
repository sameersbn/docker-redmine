#!/bin/bash
set -e

GEM_CACHE_DIR="${SETUP_DIR}/cache"

# rebuild apt cache
apt-get update

# install build dependencies
DEBIAN_FRONTEND=noninteractive apt-get install -y libcurl4-openssl-dev libssl-dev libmagickcore-dev libmagickwand-dev \
  libmysqlclient-dev libpq-dev libxslt1-dev libffi-dev libyaml-dev

# add ${REDMINE_USER} user
adduser --disabled-login --gecos 'Redmine' ${REDMINE_USER}
passwd -d ${REDMINE_USER}

# set PATH for ${REDMINE_USER} cron jobs
cat > /tmp/cron.${REDMINE_USER} <<EOF
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
EOF
crontab -u ${REDMINE_USER} /tmp/cron.${REDMINE_USER}
rm -rf /tmp/cron.${REDMINE_USER}

# create symlink to ${REDMINE_DATA_DIR}/dotfiles/.ssh
rm -rf ${REDMINE_HOME}/.ssh
sudo -HEu ${REDMINE_USER} ln -s ${REDMINE_DATA_DIR}/dotfiles/.ssh ${REDMINE_HOME}/.ssh

# create symlink to ${REDMINE_DATA_DIR}/dotfiles/.subversion
rm -rf ${REDMINE_HOME}/.subversion
sudo -HEu ${REDMINE_USER} ln -s ${REDMINE_DATA_DIR}/dotfiles/.subversion ${REDMINE_HOME}/.subversion

# install redmine, use local copy if available
mkdir -p ${REDMINE_INSTALL_DIR}
if [[ -f ${SETUP_DIR}/redmine-${REDMINE_VERSION}.tar.gz ]]; then
  tar -zvxf ${SETUP_DIR}/redmine-${REDMINE_VERSION}.tar.gz --strip=1 -C ${REDMINE_INSTALL_DIR}
else
  wget -nv "http://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz" -O - | tar -zvxf - --strip=1 -C ${REDMINE_INSTALL_DIR}
fi

cd ${REDMINE_INSTALL_DIR}

# create version file
echo "${REDMINE_VERSION}" > ${REDMINE_INSTALL_DIR}/VERSION

# HACK: we want both the pg and mysql2 gems installed, so we remove the
#       respective lines and add them at the end of the Gemfile so that they
#       are both installed.
PG_GEM=$(grep 'gem "pg"' Gemfile | awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}')
MYSQL2_GEM=$(grep 'gem "mysql2"' Gemfile | awk '{gsub(/^[ \t]+|[ \t]+$/,""); print;}')
sed '/gem "pg"/d' -i Gemfile
sed '/gem "mysql2"/d' -i Gemfile
echo "${PG_GEM}" >> Gemfile
echo "${MYSQL2_GEM}" >> Gemfile

# add gems for app server and memcache support
echo 'gem "unicorn"' >> Gemfile
echo 'gem "dalli", "~> 2.7.0"' >> Gemfile

# install gems, use cache if available
if [[ -d ${GEM_CACHE_DIR} ]]; then
  mv ${GEM_CACHE_DIR} vendor/
fi

# some gems complain about missing database.yml, shut them up!
cp config/database.yml.example config/database.yml

bundle install -j$(nproc) --without development test --path vendor/bundle

# finalize redmine installation
mkdir -p tmp tmp/pdf tmp/pids/ tmp/sockets/

# create link public/plugin_assets directory
rm -rf public/plugin_assets
ln -sf ${REDMINE_DATA_DIR}/tmp/plugin_assets public/plugin_assets

# create link tmp/thumbnails directory
rm -rf tmp/thumbnails
ln -sf ${REDMINE_DATA_DIR}/tmp/thumbnails tmp/thumbnails

# create link to tmp/secret_token.rb
ln -sf ${REDMINE_DATA_DIR}/tmp/secret_token.rb config/initializers/secret_token.rb

# symlink log -> ${REDMINE_LOG_DIR}/redmine
rm -rf log
ln -sf ${REDMINE_LOG_DIR}/redmine log

# fix permissions
chmod -R u+rwX files tmp
chown -R ${REDMINE_USER}:${REDMINE_USER} ${REDMINE_INSTALL_DIR}

# disable default nginx configuration
rm -f /etc/nginx/sites-enabled/default

# run nginx as ${REDMINE_USER} user
sed 's/user www-data/user '"${REDMINE_USER}"'/' -i /etc/nginx/nginx.conf

# move supervisord.log file to ${REDMINE_LOG_DIR}/supervisor/
sed 's|^logfile=.*|logfile='"${REDMINE_LOG_DIR}"'/supervisor/supervisord.log ;|' -i /etc/supervisor/supervisord.conf

# move nginx logs to ${REDMINE_LOG_DIR}/nginx
sed 's|access_log /var/log/nginx/access.log;|access_log '"${REDMINE_LOG_DIR}"'/nginx/access.log;|' -i /etc/nginx/nginx.conf
sed 's|error_log /var/log/nginx/error.log;|error_log '"${REDMINE_LOG_DIR}"'/nginx/error.log;|' -i /etc/nginx/nginx.conf

# setup log rotation for redmine application logs
cat > /etc/logrotate.d/redmine <<EOF
${REDMINE_LOG_DIR}/redmine/*.log {
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
autostart=true
autorestart=true
stdout_logfile=${REDMINE_LOG_DIR}/supervisor/%(program_name)s.log
stderr_logfile=${REDMINE_LOG_DIR}/supervisor/%(program_name)s.log
EOF

# configure supervisord to start unicorn
cat > /etc/supervisor/conf.d/unicorn.conf <<EOF
[program:unicorn]
priority=10
directory=${REDMINE_INSTALL_DIR}
environment=HOME=${REDMINE_HOME}
command=bundle exec unicorn_rails -E ${RAILS_ENV} -c ${REDMINE_INSTALL_DIR}/config/unicorn.rb
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

# purge build dependencies
apt-get purge -y --auto-remove \
  libcurl4-openssl-dev libssl-dev libmagickcore-dev libmagickwand-dev \
  libmysqlclient-dev libpq-dev libxslt1-dev libffi-dev libyaml-dev

# cleanup
rm -rf /var/lib/apt/lists/*
