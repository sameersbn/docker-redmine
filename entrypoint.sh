#!/bin/bash
set -e
source ${REDMINE_RUNTIME_DIR}/functions

[[ $DEBUG == true ]] && set -x

case ${1} in
  app:init|app:start|app:rake|app:backup:create|app:backup:restore)

    initialize_system
    configure_redmine
    configure_nginx

    case ${1} in
      app:start)
        migrate_database
        install_plugins
        install_themes

        if [[ -f ${REDMINE_DATA_DIR}/entrypoint.custom.sh ]]; then
          echo "Executing entrypoint.custom.sh..."
          . ${REDMINE_DATA_DIR}/entrypoint.custom.sh
        fi

        rm -rf /var/run/supervisor.sock
        exec /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf
        ;;
      app:init)
        migrate_database
        install_plugins
        install_themes
        ;;
      app:rake)
        shift 1
        execute_raketask $@
        ;;
      app:backup:create)
        shift 1
        backup_create $@
        ;;
      app:backup:restore)
        shift 1
        backup_restore $@
        ;;
    esac
    ;;
  app:help)
    echo "Available options:"
    echo " app:start          - Starts the Redmine server (default)"
    echo " app:init           - Initialize the Redmine server (e.g. create databases, install plugins/themes), but don't start it."
    echo " app:rake <task>    - Execute a rake task."
    echo " app:backup:create  - Create a backup."
    echo " app:backup:restore - Restore an existing backup."
    echo " app:help           - Displays the help"
    echo " [command]          - Execute the specified command, eg. bash."
    ;;
  *)
    exec "$@"
    ;;
esac
