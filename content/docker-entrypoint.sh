#!/bin/bash

for f in /docker-entrypoint-init.d/*; do
  case "$f" in
    *.sh)  echo "$0: running $f"; . "$f" ;;
    *)     echo "$0: ignoring $f" ;;
   esac
   echo
done

echo_log "Starting Supervisor. CTRL-C will stop the container."
exec /usr/bin/supervisord -c /etc/supervisord.conf >> /dev/null
