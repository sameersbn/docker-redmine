#!/bin/bash
set -e

SSL_CERTIFICATES_DIR="${REDMINE_DATA_DIR}/certs"
SYSCONF_TEMPLATES_DIR="${SETUP_DIR}/config"
USERCONF_TEMPLATES_DIR="${REDMINE_DATA_DIR}/config"

REDMINE_DATABASE_CONFIG="${REDMINE_INSTALL_DIR}/config/database.yml"
REDMINE_UNICORN_CONFIG="${REDMINE_INSTALL_DIR}/config/unicorn.rb"
REDMINE_MEMCACHED_CONFIG="${REDMINE_INSTALL_DIR}/config/additional_environment.rb"
REDMINE_SMTP_CONFIG="${REDMINE_INSTALL_DIR}/config/initializers/smtp_settings.rb"
REDMINE_NGINX_CONFIG="/etc/nginx/sites-enabled/redmine"

DB_ADAPTER=${DB_ADAPTER:-}
DB_ENCODING=${DB_ENCODING:-}
DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}
DB_POOL=${DB_POOL:-5}

# backward compatibility
case ${DB_TYPE} in
  mysql) DB_ADAPTER=${DB_ADAPTER:-mysql2} ;;
  postgres) DB_ADAPTER=${DB_ADAPTER:-postgresql} ;;
esac


MEMCACHED_HOST=${MEMCACHED_HOST:-}
MEMCACHED_PORT=${MEMCACHED_PORT:-}

SMTP_METHOD=${SMTP_METHOD:-smtp}
SMTP_DOMAIN=${SMTP_DOMAIN:-www.gmail.com}
SMTP_HOST=${SMTP_HOST:-smtp.gmail.com}
SMTP_PORT=${SMTP_PORT:-587}
SMTP_USER=${SMTP_USER:-}
SMTP_PASS=${SMTP_PASS:-}
SMTP_OPENSSL_VERIFY_MODE=${SMTP_OPENSSL_VERIFY_MODE:-}
SMTP_STARTTLS=${SMTP_STARTTLS:-true}
SMTP_TLS=${SMTP_TLS:-false}
SMTP_CA_ENABLED=${SMTP_CA_ENABLED:-false}
SMTP_CA_PATH=${SMTP_CA_PATH:-$REDMINE_DATA_DIR/certs}
SMTP_CA_FILE=${SMTP_CA_FILE:-$REDMINE_DATA_DIR/certs/ca.crt}
if [[ -n ${SMTP_USER} ]]; then
  SMTP_ENABLED=${SMTP_ENABLED:-true}
  SMTP_AUTHENTICATION=${SMTP_AUTHENTICATION:-:login}
fi
SMTP_ENABLED=${SMTP_ENABLED:-false}

IMAP_ENABLED=${IMAP_ENABLED:-false}
IMAP_USER=${IMAP_USER:-${SMTP_USER}}
IMAP_PASS=${IMAP_PASS:-${SMTP_PASS}}
IMAP_HOST=${IMAP_HOST:-imap.gmail.com}
IMAP_PORT=${IMAP_PORT:-993}
IMAP_SSL=${IMAP_SSL:-true}
IMAP_INTERVAL=${IMAP_INTERVAL:-30}

INCOMING_EMAIL_UNKNOWN_USER=${INCOMING_EMAIL_UNKNOWN_USER:-ignore}
INCOMING_EMAIL_NO_PERMISSION_CHECK=${INCOMING_EMAIL_NO_PERMISSION_CHECK:-false}
INCOMING_EMAIL_NO_ACCOUNT_NOTICE=${INCOMING_EMAIL_NO_ACCOUNT_NOTICE:-true}
INCOMING_EMAIL_DEFAULT_GROUP=${INCOMING_EMAIL_DEFAULT_GROUP:-}
INCOMING_EMAIL_PROJECT=${INCOMING_EMAIL_PROJECT:-}
INCOMING_EMAIL_STATUS=${INCOMING_EMAIL_STATUS:-}
INCOMING_EMAIL_TRACKER=${INCOMING_EMAIL_TRACKER:-}
INCOMING_EMAIL_CATEGORY=${INCOMING_EMAIL_CATEGORY:-}
INCOMING_EMAIL_PRIORITY=${INCOMING_EMAIL_PRIORITY:-}
INCOMING_EMAIL_PRIVATE=${INCOMING_EMAIL_PRIVATE:-}
INCOMING_EMAIL_ALLOW_OVERRIDE=${INCOMING_EMAIL_ALLOW_OVERRIDE:-}

REDMINE_PORT=${REDMINE_PORT:-}
REDMINE_HTTPS=${REDMINE_HTTPS:-false}
REDMINE_RELATIVE_URL_ROOT=${REDMINE_RELATIVE_URL_ROOT:-}
REDMINE_FETCH_COMMITS=${REDMINE_FETCH_COMMITS:-disable}

REDMINE_HTTPS_HSTS_ENABLED=${REDMINE_HTTPS_HSTS_ENABLED:-true}
REDMINE_HTTPS_HSTS_MAXAGE=${REDMINE_HTTPS_HSTS_MAXAGE:-31536000}

NGINX_WORKERS=${NGINX_WORKERS:-1}
NGINX_MAX_UPLOAD_SIZE=${NGINX_MAX_UPLOAD_SIZE:-20m}

SSL_CERTIFICATE_PATH=${SSL_CERTIFICATE_PATH:-${SSL_CERTIFICATES_DIR}/redmine.crt}
SSL_KEY_PATH=${SSL_KEY_PATH:-${SSL_CERTIFICATES_DIR}/redmine.key}
SSL_DHPARAM_PATH=${SSL_DHPARAM_PATH:-${SSL_CERTIFICATES_DIR}/dhparam.pem}
SSL_VERIFY_CLIENT=${SSL_VERIFY_CLIENT:-off}

UNICORN_WORKERS=${UNICORN_WORKERS:-2}
UNICORN_TIMEOUT=${UNICORN_TIMEOUT:-60}

# is a mysql or postgresql database linked?
# requires that the mysql or postgresql containers have exposed
# port 3306 and 5432 respectively.
if [[ -n ${MYSQL_PORT_3306_TCP_ADDR} ]]; then
  DB_ADAPTER=${DB_ADAPTER:-mysql2}
  DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
  DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}

  # support for linked sameersbn/mysql image
  DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
  DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
  DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}

  # support for linked orchardup/mysql and centurylink/mysql image
  # also supports official mysql image
  DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
  DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
  DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
elif [[ -n ${POSTGRESQL_PORT_5432_TCP_ADDR} ]]; then
  DB_ADAPTER=${DB_ADAPTER:-postgresql}
  DB_HOST=${DB_HOST:-${POSTGRESQL_PORT_5432_TCP_ADDR}}
  DB_PORT=${DB_PORT:-${POSTGRESQL_PORT_5432_TCP_PORT}}

  # support for linked official postgres image
  DB_USER=${DB_USER:-${POSTGRESQL_ENV_POSTGRES_USER}}
  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_POSTGRES_PASSWORD}}
  DB_NAME=${DB_NAME:-${DB_USER}}

  # support for linked sameersbn/postgresql image
  DB_USER=${DB_USER:-${POSTGRESQL_ENV_DB_USER}}
  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_DB_PASS}}
  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_DB_NAME}}

  # support for linked orchardup/postgresql image
  DB_USER=${DB_USER:-${POSTGRESQL_ENV_POSTGRESQL_USER}}
  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_POSTGRESQL_PASS}}
  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_POSTGRESQL_DB}}

  # support for linked paintedfox/postgresql image
  DB_USER=${DB_USER:-${POSTGRESQL_ENV_USER}}
  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_PASS}}
  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_DB}}
fi

if [[ -z ${DB_HOST} ]]; then
  echo "ERROR: "
  echo "  Please configure the database connection."
  echo "  Refer http://git.io/JkE-cw for more information."
  echo "  Cannot continue without a database. Aborting..."
  exit 1
fi

# set default port number if not specified
DB_ADAPTER=${DB_ADAPTER:-mysql2}
case ${DB_ADAPTER} in
  mysql2)
    DB_ENCODING=${DB_ENCODING:-utf8}
    DB_PORT=${DB_PORT:-3306}
    ;;
  postgresql)
    DB_ENCODING=${DB_ENCODING:-unicode}
    DB_PORT=${DB_PORT:-5432}
    ;;
  *)
    echo
    echo "ERROR: "
    echo "  Please specify the database type in use via the DB_ADAPTER configuration option."
    echo "  Accepted values are \"postgresql\" or \"mysql2\". Aborting..."
    echo
    return 1
    ;;
esac

# set the default user and database
DB_NAME=${DB_NAME:-redmine_production}
DB_USER=${DB_USER:-root}

# is a memcached container linked?
if [[ -n ${MEMCACHED_PORT_11211_TCP_ADDR} ]]; then
  MEMCACHE_HOST=${MEMCACHE_HOST:-${MEMCACHED_PORT_11211_TCP_ADDR}}
  MEMCACHE_PORT=${MEMCACHE_PORT:-${MEMCACHED_PORT_11211_TCP_PORT}}
fi

# fallback to using the default memcached port 11211
MEMCACHE_PORT=${MEMCACHE_PORT:-11211}

# enable / disable memcached
if [[ -n ${MEMCACHE_HOST} ]]; then
  MEMCACHE_ENABLED=true
fi
MEMCACHE_ENABLED=${MEMCACHE_ENABLED:-false}

case ${REDMINE_HTTPS} in
  true)
    REDMINE_PORT=${REDMINE_PORT:-443}
    NGINX_X_FORWARDED_PROTO=${NGINX_X_FORWARDED_PROTO:-https}
    ;;
  *)
    REDMINE_PORT=${REDMINE_PORT:-80}
    NGINX_X_FORWARDED_PROTO=${NGINX_X_FORWARDED_PROTO:-\$scheme}
    ;;
esac

## Execute a command as REDMINE_USER
exec_as_redmine() {
  sudo -HEu ${REDMINE_USER} "$@"
}

## Copies configuration template to the destination as the specified USER
### Looks up for overrides in ${USERCONF_TEMPLATES_DIR} before using the defaults from ${SYSCONF_TEMPLATES_DIR}
# $1: copy-as user
# $2: source file
# $3: destination location
install_template() {
  local USR=${1}
  local SRC=${2}
  local DEST=${3}
  if [[ -f ${USERCONF_TEMPLATES_DIR}/${SRC} ]]; then
    sudo -HEu ${USR} cp ${USERCONF_TEMPLATES_DIR}/${SRC} ${DEST}
  elif [[ -f ${SYSCONF_TEMPLATES_DIR}/${SRC} ]]; then
    sudo -HEu ${USR} cp ${SYSCONF_TEMPLATES_DIR}/${SRC} ${DEST}
  fi
}

## Replace placeholders with values
# $1: file with placeholders to replace
# $x: placeholders to replace
update_template() {
  local FILE=${1?missing argument}
  shift

  [[ ! -f ${FILE} ]] && return 1

  local VARIABLES=($@)
  local USR=$(stat -c %U ${FILE})
  local tmp_file=$(mktemp)
  cp -a "${FILE}" ${tmp_file}

  local variable
  for variable in ${VARIABLES[@]}; do
    # Keep the compatibilty: {{VAR}} => ${VAR}
    sed -ri "s/[{]{2}$variable[}]{2}/\${$variable}/g" ${tmp_file}
  done

  # Replace placeholders
  (
    export ${VARIABLES[@]}
    local IFS=":"; sudo -HEu ${USR} envsubst "${VARIABLES[*]/#/$}" < ${tmp_file} > ${FILE}
  )
  rm -f ${tmp_file}
}

## Adapt uid and gid for ${REDMINE_USER}:${REDMINE_USER}
USERMAP_ORIG_UID=$(id -u ${REDMINE_USER})
USERMAP_ORIG_GID=$(id -g ${REDMINE_USER})
USERMAP_GID=${USERMAP_GID:-${USERMAP_UID:-$USERMAP_ORIG_GID}}
USERMAP_UID=${USERMAP_UID:-$USERMAP_ORIG_UID}
if [[ ${USERMAP_UID} != ${USERMAP_ORIG_UID} ]] || [[ ${USERMAP_GID} != ${USERMAP_ORIG_GID} ]]; then
  echo "Adapting uid and gid for ${REDMINE_USER}:${REDMINE_USER} to $USERMAP_UID:$USERMAP_GID"
  groupmod -g ${USERMAP_GID} ${REDMINE_USER}
  sed -i -e "s/:${USERMAP_ORIG_UID}:${USERMAP_GID}:/:${USERMAP_UID}:${USERMAP_GID}:/" /etc/passwd
  find ${REDMINE_HOME} -path ${REDMINE_DATA_DIR}/\* -prune -o -print0 | xargs -0 chown -h ${REDMINE_USER}:${REDMINE_USER}
fi

# take ownership of entire data directory
chown -R ${REDMINE_USER}:${REDMINE_USER} ${REDMINE_DATA_DIR}

# create the .ssh directory
exec_as_redmine mkdir -p ${REDMINE_DATA_DIR}/dotfiles/.ssh/

# generate ssh keys
if [[ ! -e ${REDMINE_DATA_DIR}/dotfiles/.ssh/id_rsa || ! -e ${REDMINE_DATA_DIR}/dotfiles/.ssh/id_rsa.pub ]]; then
  echo "Generating SSH keys..."
  rm -rf ${REDMINE_DATA_DIR}/dotfiles/.ssh/id_rsa ${REDMINE_DATA_DIR}/dotfiles/.ssh/id_rsa.pub
  exec_as_redmine ssh-keygen -t rsa -N "" -f ${REDMINE_DATA_DIR}/dotfiles/.ssh/id_rsa
fi

# make sure the ssh keys have the right ownership and permissions
chmod 600 ${REDMINE_DATA_DIR}/dotfiles/.ssh/id_rsa ${REDMINE_DATA_DIR}/dotfiles/.ssh/id_rsa.pub
chmod 700 ${REDMINE_DATA_DIR}/dotfiles/.ssh

# create the .subversion directory
mkdir -p ${REDMINE_DATA_DIR}/dotfiles/.subversion/

# fix ownership of the ${REDMINE_DATA_DIR}dotfiles/ directory
chown -R ${REDMINE_USER}:${REDMINE_USER} ${REDMINE_DATA_DIR}/dotfiles

# fix ownership of ${REDMINE_DATA_DIR}/tmp/
mkdir -p ${REDMINE_DATA_DIR}/tmp/
chown -R ${REDMINE_USER}:${REDMINE_USER} ${REDMINE_DATA_DIR}/tmp/

# populate ${REDMINE_LOG_DIR}
mkdir -m 0755 -p ${REDMINE_LOG_DIR}/supervisor  && chown -R root:root ${REDMINE_LOG_DIR}/supervisor
mkdir -m 0755 -p ${REDMINE_LOG_DIR}/nginx       && chown -R ${REDMINE_USER}:${REDMINE_USER} ${REDMINE_LOG_DIR}/nginx
mkdir -m 0755 -p ${REDMINE_LOG_DIR}/redmine     && chown -R ${REDMINE_USER}:${REDMINE_USER} ${REDMINE_LOG_DIR}/redmine

# fix permission and ownership of ${REDMINE_DATA_DIR}
chmod 755 ${REDMINE_DATA_DIR}
chown ${REDMINE_USER}:${REDMINE_USER} ${REDMINE_DATA_DIR}

# set executable flags on ${REDMINE_DATA_DIR} (needed if mounted from a data-only
# container using --volumes-from)
chmod +x ${REDMINE_DATA_DIR}

cd ${REDMINE_INSTALL_DIR}

# copy configuration templates
install_template ${REDMINE_USER} redmine/database.yml ${REDMINE_DATABASE_CONFIG}
install_template ${REDMINE_USER} redmine/unicorn.rb ${REDMINE_UNICORN_CONFIG}

if [[ -n ${REDMINE_RELATIVE_URL_ROOT} ]]; then
  install_template ${REDMINE_USER} redmine/config.ru config.ru
fi

if [[ ${SMTP_ENABLED} == true ]]; then
  install_template ${REDMINE_USER} redmine/smtp_settings.rb ${REDMINE_SMTP_CONFIG}
fi

if [[ ${MEMCACHE_ENABLED} == true ]]; then
  install_template ${REDMINE_USER} redmine/additional_environment.rb ${REDMINE_MEMCACHED_CONFIG}
fi

if [[ ${REDMINE_HTTPS} == true ]]; then
  if [[ -f ${SSL_CERTIFICATE_PATH} && -f ${SSL_KEY_PATH} ]]; then
    install_template root nginx/redmine-ssl ${REDMINE_NGINX_CONFIG}
  else
    echo "SSL keys and certificates were not found."
    echo "Assuming that the container is running behind a HTTPS enabled load balancer."
    install_template root nginx/redmine ${REDMINE_NGINX_CONFIG}
  fi
else
  install_template root nginx/redmine ${REDMINE_NGINX_CONFIG}
fi

# configure database
update_template ${REDMINE_DATABASE_CONFIG} \
  DB_ADAPTER \
  DB_ENCODING \
  DB_HOST \
  DB_PORT \
  DB_NAME \
  DB_USER \
  DB_PASS \
  DB_POOL

if [[ ${DB_ADAPTER} == postgresql ]]; then
  exec_as_redmine sed -i "/reconnect: /d" ${REDMINE_DATABASE_CONFIG}
fi

# configure secure-cookie if using SSL/TLS
if [[ ${REDMINE_HTTPS} == true ]]; then
  exec_as_redmine sed -i "s/:key => '_redmine_session'/:secure => true, :key => '_redmine_session'/" config/application.rb
fi

# configure memcached
if [[ ${MEMCACHE_ENABLED} == true ]]; then
  echo "Enabling memcache..."
  update_template ${REDMINE_MEMCACHED_CONFIG} \
    MEMCACHE_HOST \
    MEMCACHE_PORT
fi

# configure nginx
sed -i "s|worker_processes .*|worker_processes '"${NGINX_WORKERS}"';|" /etc/nginx/nginx.conf

if [[ ! -f ${CA_CERTIFICATES_PATH} ]]; then
  sed -i "/{{CA_CERTIFICATES_PATH}}/d" ${REDMINE_NGINX_CONFIG}
fi

if [[ ! -f ${SSL_DHPARAM_PATH} ]]; then
  sed -i "/{{SSL_DHPARAM_PATH}}/d" ${REDMINE_NGINX_CONFIG}
fi

if [[ ! -f ${REDMINE_HTTPS_HSTS_ENABLED} ]]; then
  sed -i "/{{REDMINE_HTTPS_HSTS_MAXAGE}}/d" ${REDMINE_NGINX_CONFIG}
fi

update_template ${REDMINE_NGINX_CONFIG} \
  REDMINE_INSTALL_DIR \
  REDMINE_LOG_DIR \
  REDMINE_PORT \
  SSL_CERTIFICATE_PATH \
  SSL_KEY_PATH \
  SSL_DHPARAM_PATH \
  SSL_VERIFY_CLIENT \
  CA_CERTIFICATES_PATH \
  NGINX_MAX_UPLOAD_SIZE \
  NGINX_X_FORWARDED_PROTO \
  REDMINE_HTTPS_HSTS_MAXAGE

# configure unicorn
update_template ${REDMINE_UNICORN_CONFIG} \
  REDMINE_INSTALL_DIR \
  REDMINE_USER \
  UNICORN_WORKERS \
  UNICORN_TIMEOUT

# configure relative_url_root
if [[ -n ${REDMINE_RELATIVE_URL_ROOT} ]]; then
  update_template ${REDMINE_UNICORN_CONFIG} REDMINE_RELATIVE_URL_ROOT
  sed -i "s|# alias ${REDMINE_INSTALL_DIR}/public|alias ${REDMINE_INSTALL_DIR}/public|" ${REDMINE_NGINX_CONFIG}
  sed -i "s|{{REDMINE_RELATIVE_URL_ROOT}}|${REDMINE_RELATIVE_URL_ROOT}|" ${REDMINE_NGINX_CONFIG}
else
  exec_as_redmine sed '/{{REDMINE_RELATIVE_URL_ROOT}}/d' -i ${REDMINE_UNICORN_CONFIG}
  sed -i "s|{{REDMINE_RELATIVE_URL_ROOT}}|/|" ${REDMINE_NGINX_CONFIG}
fi

# disable ipv6 support
if [[ ! -f /proc/net/if_inet6 ]]; then
  sed -i \
    -e "/listen \[::\]:80/d" \
    -e "/listen \[::\]:443/d" \
    ${REDMINE_NGINX_CONFIG}
fi

# configure mail delivery
if [[ ${SMTP_ENABLED} == true ]]; then
  if [[ -z "${SMTP_USER}" ]]; then
    exec_as_redmine sed -i \
      -e '/{{SMTP_USER}}/d' \
      -e '/{{SMTP_PASS}}/d' \
      ${REDMINE_SMTP_CONFIG}
  else
    if [[ -z "${SMTP_PASS}" ]]; then
      exec_as_redmine sed -i '/{{SMTP_PASS}}/d' ${REDMINE_SMTP_CONFIG}
    fi
  fi

  if [[ -z "${SMTP_AUTHENTICATION}" ]]; then
    exec_as_redmine sed -i '/{{SMTP_AUTHENTICATION}}/d' ${REDMINE_SMTP_CONFIG}
  fi

  if [[ -z "${SMTP_OPENSSL_VERIFY_MODE}" ]]; then
    exec_as_redmine sed -i '/{{SMTP_OPENSSL_VERIFY_MODE}}/d' ${REDMINE_SMTP_CONFIG}
  fi

  update_template ${REDMINE_SMTP_CONFIG} \
    SMTP_METHOD \
    SMTP_HOST \
    SMTP_PORT \
    SMTP_DOMAIN \
    SMTP_USER \
    SMTP_PASS \
    SMTP_AUTHENTICATION \
    SMTP_OPENSSL_VERIFY_MODE \
    SMTP_STARTTLS \
    SMTP_TLS

  if [[ ${SMTP_CA_ENABLED} == true ]]; then
    if [[ -d ${SMTP_CA_PATH} ]]; then
      update_template ${REDMINE_SMTP_CONFIG} SMTP_CA_PATH
    fi
    if [[ -f ${SMTP_CA_FILE} ]]; then
      update_template ${REDMINE_SMTP_CONFIG} SMTP_CA_FILE
    fi
  else
    exec_as_redmine sed -i \
      -e "/{{SMTP_CA_PATH}}/d" \
      -e "/{{SMTP_CA_FILE}}/d" \
      ${REDMINE_SMTP_CONFIG}
  fi
fi

# create file uploads directory
mkdir -p ${REDMINE_DATA_DIR}/files
chmod 755 ${REDMINE_DATA_DIR}/files
chown ${REDMINE_USER}:${REDMINE_USER} ${REDMINE_DATA_DIR}/files

# symlink file store
rm -rf files
if [[ -d /redmine/files ]]; then
  # for backward compatibility, user should mount the volume at ${REDMINE_DATA_DIR}
  echo "WARNING: "
  echo "  The data volume path has now been changed to ${REDMINE_DATA_DIR}/files."
  echo "  Refer http://git.io/H59-lg for migration information."
  echo "  Setting up backward compatibility..."
  chmod 755 /redmine/files
  chown ${REDMINE_USER}:${REDMINE_USER} /redmine/files
  ln -sf /redmine/files
else
  ln -sf ${REDMINE_DATA_DIR}/files
fi

# due to the nature of docker and its use cases, we allow some time
# for the database server to come online.
case ${DB_ADAPTER} in
  mysql2)
    prog="mysqladmin -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASS:+-p$DB_PASS} status"
    ;;
  postgresql)
    prog=$(find /usr/lib/postgresql/ -name pg_isready)
    prog="${prog} -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -t 1"
    ;;
esac

timeout=60
echo -n "Waiting for database server to accept connections"
while ! ${prog} >/dev/null 2>&1
do
  timeout=$(expr $timeout - 1)
  if [[ $timeout -eq 0 ]]; then
    echo -e "\nCould not connect to database server. Aborting..."
    exit 1
  fi
  echo -n "."
  sleep 1
done
echo

# migrate database if the redmine version has changed.
CURRENT_VERSION=
[[ -f ${REDMINE_DATA_DIR}/tmp/VERSION ]] && CURRENT_VERSION=$(cat ${REDMINE_DATA_DIR}/tmp/VERSION)
if [[ ${REDMINE_VERSION} != ${CURRENT_VERSION} ]]; then
  # recreate the tmp directory
  rm -rf ${REDMINE_DATA_DIR}/tmp
  exec_as_redmine mkdir -p ${REDMINE_DATA_DIR}/tmp/
  chmod -R u+rwX ${REDMINE_DATA_DIR}/tmp/

  # create the tmp/thumbnails directory
  exec_as_redmine mkdir -p ${REDMINE_DATA_DIR}/tmp/thumbnails

  # create the plugin_assets directory
  exec_as_redmine mkdir -p ${REDMINE_DATA_DIR}/tmp/plugin_assets

  # copy the installed gems to tmp/bundle and move the Gemfile.lock
  exec_as_redmine cp -a vendor/bundle ${REDMINE_DATA_DIR}/tmp/
  exec_as_redmine cp -a Gemfile.lock ${REDMINE_DATA_DIR}/tmp/

  echo "Migrating database. Please be patient, this could take a while..."
  exec_as_redmine bundle exec rake db:create
  exec_as_redmine bundle exec rake db:migrate

  # clear sessions and application cache
  exec_as_redmine bundle exec rake tmp:cache:clear >/dev/null
  exec_as_redmine bundle exec rake tmp:sessions:clear >/dev/null

  echo "Generating secure token..."
  exec_as_redmine bundle exec rake generate_secret_token >/dev/null

  # update version file
  echo ${REDMINE_VERSION} | exec_as_redmine tee --append ${REDMINE_DATA_DIR}/tmp/VERSION >/dev/null
fi

# setup cronjobs
crontab -u ${REDMINE_USER} -l >/tmp/cron.${REDMINE_USER}

# create a cronjob to periodically fetch commits
case ${REDMINE_FETCH_COMMITS} in
  hourly|daily|monthly)
    if ! grep -q 'Repository.fetch_changesets' /tmp/cron.${REDMINE_USER}; then
      case ${REDMINE_VERSION} in
        2.*) echo "@${REDMINE_FETCH_COMMITS} cd ${REDMINE_HOME}/redmine && ./script/rails runner \"Repository.fetch_changesets\" -e ${RAILS_ENV} >> log/cron_rake.log 2>&1" >>/tmp/cron.${REDMINE_USER} ;;
        3.*) echo "@${REDMINE_FETCH_COMMITS} cd ${REDMINE_HOME}/redmine && ./bin/rails runner \"Repository.fetch_changesets\" -e ${RAILS_ENV} >> log/cron_rake.log 2>&1" >>/tmp/cron.${REDMINE_USER} ;;
        *) echo "ERROR: Unsupported Redmine version (${REDMINE_VERSION})" && exit 1 ;;
      esac
    fi
    ;;
esac

# create a cronjob for receiving emails (comments, etc.)
if [[ ${IMAP_ENABLED} == true ]]; then
  if ! grep -q 'redmine:email:receive_imap' /tmp/cron.${REDMINE_USER}; then
    case ${INCOMING_EMAIL_NO_PERMISSION_CHECK} in
      true)  INCOMING_EMAIL_NO_PERMISSION_CHECK=1 ;;
      false) INCOMING_EMAIL_NO_PERMISSION_CHECK=0 ;;
    esac

    case ${INCOMING_EMAIL_PRIVATE} in
      true)  INCOMING_EMAIL_PRIVATE=1 ;;
      false) INCOMING_EMAIL_PRIVATE=0 ;;
    esac

    INCOMING_EMAIL_OPTIONS="${INCOMING_EMAIL_UNKNOWN_USER:+unknown_user=${INCOMING_EMAIL_UNKNOWN_USER}} \
      ${INCOMING_EMAIL_NO_PERMISSION_CHECK:+no_permission_check=${INCOMING_EMAIL_NO_PERMISSION_CHECK}} \
      ${INCOMING_EMAIL_NO_ACCOUNT_NOTICE:+no_account_notice=${INCOMING_EMAIL_NO_ACCOUNT_NOTICE}} \
      ${INCOMING_EMAIL_DEFAULT_GROUP:+default_group=${INCOMING_EMAIL_DEFAULT_GROUP}} \
      ${INCOMING_EMAIL_PROJECT:+project=${INCOMING_EMAIL_PROJECT}} \
      ${INCOMING_EMAIL_STATUS:+status=${INCOMING_EMAIL_STATUS}} \
      ${INCOMING_EMAIL_TRACKER:+tracker=${INCOMING_EMAIL_TRACKER}} \
      ${INCOMING_EMAIL_CATEGORY:+category=${INCOMING_EMAIL_CATEGORY}} \
      ${INCOMING_EMAIL_PRIORITY:+priority=${INCOMING_EMAIL_PRIORITY}} \
      ${INCOMING_EMAIL_PRIVATE:+private=${INCOMING_EMAIL_PRIVATE}} \
      ${INCOMING_EMAIL_ALLOW_OVERRIDE:+allow_override=${INCOMING_EMAIL_ALLOW_OVERRIDE}}"
    echo "*/${IMAP_INTERVAL} * * * * cd ${REDMINE_HOME}/redmine && bundle exec rake redmine:email:receive_imap host=${IMAP_HOST} port=${IMAP_PORT} ssl=${IMAP_SSL} username=${IMAP_USER} password=${IMAP_PASS} ${INCOMING_EMAIL_OPTIONS} RAILS_ENV=${RAILS_ENV} >> log/cron_rake.log 2>&1" >>/tmp/cron.${REDMINE_USER}
  fi
fi

# install the cronjobs
crontab -u ${REDMINE_USER} /tmp/cron.${REDMINE_USER}
rm -rf /tmp/cron.${REDMINE_USER}

# remove vendor/bundle and symlink to ${REDMINE_DATA_DIR}/tmp/bundle
rm -rf vendor/bundle Gemfile.lock
ln -sf ${REDMINE_DATA_DIR}/tmp/bundle vendor/bundle
ln -sf ${REDMINE_DATA_DIR}/tmp/Gemfile.lock Gemfile.lock

# install user plugins
if [[ -d ${REDMINE_DATA_DIR}/plugins ]]; then
  echo "Installing plugins..."
  rsync -avq --chown=${REDMINE_USER}:${REDMINE_USER} ${REDMINE_DATA_DIR}/plugins/ ${REDMINE_INSTALL_DIR}/plugins/

  # plugins/init script is renamed to plugins/post-install.sh
  if [[ -f ${REDMINE_DATA_DIR}/plugins/init ]]; then
    mv ${REDMINE_DATA_DIR}/plugins/init ${REDMINE_DATA_DIR}/plugins/post-install.sh
  fi

  # execute plugins/pre-install.sh script
  if [[ -f ${REDMINE_DATA_DIR}/plugins/pre-install.sh ]]; then
    echo "Executing plugins/pre-install.sh script..."
    . ${REDMINE_DATA_DIR}/plugins/pre-install.sh
  fi

  # install gems and migrate the plugins when plugins are added/removed
  CURRENT_SHA1=
  [[ -f ${REDMINE_DATA_DIR}/tmp/plugins.sha1 ]] && CURRENT_SHA1=$(cat ${REDMINE_DATA_DIR}/tmp/plugins.sha1)
  PLUGINS_SHA1=$(find ${REDMINE_DATA_DIR}/plugins -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum | awk '{print $1}')
  if [[ ${CURRENT_SHA1} != ${PLUGINS_SHA1} ]]; then
    # remove the existing plugin assets
    # this ensures there is no cruft when a plugin is removed.
    rm -rf ${REDMINE_DATA_DIR}/tmp/plugin_assets/*

    echo "Installing gems required by plugins..."
    exec_as_redmine bundle install --without development test --path vendor/bundle

    echo "Migrating plugins. Please be patient, this could take a while..."
    exec_as_redmine bundle exec rake redmine:plugins:migrate

    # save SHA1
    echo -n ${PLUGINS_SHA1} > ${REDMINE_DATA_DIR}/tmp/plugins.sha1
  fi

  # execute plugins post-install.sh script
  if [[ -f ${REDMINE_DATA_DIR}/plugins/post-install.sh ]]; then
    echo "Executing plugins/post-install.sh script..."
    . ${REDMINE_DATA_DIR}/plugins/post-install.sh
  fi
else
  # make sure the plugins.sha1 is not present
  rm -rf ${REDMINE_DATA_DIR}/tmp/plugins.sha1
fi

# install user themes
if [[ -d ${REDMINE_DATA_DIR}/themes ]]; then
  echo "Installing themes..."
  rsync -avq --chown=${REDMINE_USER}:${REDMINE_USER} ${REDMINE_DATA_DIR}/themes/ ${REDMINE_INSTALL_DIR}/public/themes/
fi

# execute entrypoint customization script
if [[ -f ${REDMINE_DATA_DIR}/entrypoint.custom.sh ]]; then
  echo "Executing entrypoint.custom.sh..."
  . ${REDMINE_DATA_DIR}/entrypoint.custom.sh
fi

appStart () {
  # remove stale unicorn pid if it exists.
  rm -rf tmp/pids/unicorn.pid

  # remove state unicorn socket if it exists
  rm -rf tmp/sockets/redmine.socket

  # start supervisord
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
}

appRake () {
  if [[ -z ${1} ]]; then
    echo "Please specify the rake task to execute. See http://www.redmine.org/projects/redmine/wiki/RedmineRake"
    return 1
  fi
  echo "Running redmine rake task..."
  exec_as_redmine bundle exec rake $@
}

appHelp () {
  echo "Available options:"
  echo " app:start          - Starts the redmine server (default)"
  echo " app:rake <task>    - Execute a rake task."
  echo " app:help           - Displays the help"
  echo " [command]          - Execute the specified linux command eg. bash."
}

case ${1} in
  app:start)
    appStart
    ;;
  app:rake)
    shift 1
    appRake $@
    ;;
  app:help)
    appHelp
    ;;
  *)
    if [[ -x ${1} ]]; then
      ${1}
    else
      prog=$(which ${1})
      if [[ -n ${prog} ]] ; then
        shift 1
        $prog $@
      else
        appHelp
      fi
    fi
    ;;
esac

exit 0
