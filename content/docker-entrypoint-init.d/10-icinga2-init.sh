#!/bin/bash

#/******************************************************************************
# * docker-icinga2                                                             *
# * Dockerfile for Icinga 2 and Icinga Web 2                                   *
# * Copyright (C) 2015 Icinga Development Team (http://www.icinga.org)         *
# *                                                                            *
# * This program is free software; you can redistribute it and/or              *
# * modify it under the terms of the GNU General Public License                *
# * as published by the Free Software Foundation; either version 2             *
# * of the License, or (at your option) any later version.                     *
# *                                                                            *
# * This program is distributed in the hope that it will be useful,            *
# * but WITHOUT ANY WARRANTY; without even the implied warranty of             *
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
# * GNU General Public License for more details.                               *
# *                                                                            *
# * You should have received a copy of the GNU General Public License          *
# * along with this program; if not, write to the Free Software Foundation     *
# * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.             *
# ******************************************************************************/

set -e

function echo_log {
	DATE='date +%Y/%m/%d:%H:%M:%S'
	echo `$DATE`" $1"
}

initfile=/etc/icinga2/docker-init.done

echo_log "Validating the icinga2 configuration first."
if ! icinga2 daemon -C; then
	echo_log "Icinga 2 config validation failed. Stopping the container."
	exit 1
fi


if [ ! -f "${initfile}" ]; then
        echo_log "Starting DB schema import. This might take a while (20sec+)."
        mysql_install_db --user=mysql --ldata=/var/lib/mysql 2>&1 >/dev/null
        /usr/bin/mysqld_safe 2>&1 >/dev/null &
        sleep 10s
        mysql -uroot -e "DROP DATABASE IF EXISTS test ;"
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS icinga ; GRANT ALL ON icinga.* TO icinga@localhost IDENTIFIED BY 'icinga'; FLUSH PRIVILEGES;"
        mysql -uicinga -picinga icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS icingaweb2 ; GRANT ALL ON icingaweb2.* TO icingaweb2@localhost IDENTIFIED BY 'icingaweb2'; FLUSH PRIVILEGES;"
        mysql -uicingaweb2 -picingaweb2 icingaweb2 < /usr/share/doc/icingaweb2/schema/mysql.schema.sql
        mysql -uicingaweb2 -picingaweb2 icingaweb2 -e "INSERT INTO icingaweb_group (id, name) VALUES (1, 'Administrators');"
        mysql -uicingaweb2 -picingaweb2 icingaweb2 -e "INSERT INTO icingaweb_group_membership (group_id, username) VALUES (1, 'admin');"
        mysql -uicingaweb2 -picingaweb2 icingaweb2 -e "INSERT INTO icingaweb_user (name, active, password_hash) VALUES ('admin', 1, '\$1\$iQSrnmO9\$T3NVTu0zBkfuim4lWNRmH.');"
        killall mysqld
        sleep 1s

        echo_log "Enabling icinga2 features."
        # enable icinga2 features if not already there
        icinga2 feature enable ido-mysql command

        echo_log "Enabling icingaweb2 modules."
        if [[ -L /etc/icingaweb2/enabledModules/monitoring ]]; then echo "Symlink for /etc/icingaweb2/enabledModules/monitoring exists already...skipping"; else ln -s /usr/share/icingaweb2/modules/monitoring /etc/icingaweb2/enabledModules/monitoring; fi
        if [[ -L /etc/icingaweb2/enabledModules/doc ]]; then echo "Symlink for /etc/icingaweb2/enabledModules/doc exists already...skipping"; else ln -s /usr/share/icingaweb2/modules/doc /etc/icingaweb2/enabledModules/doc; fi

        touch ${initfile}
fi
