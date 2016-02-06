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

if [[ -n $ICINGA2_FEATURE_GRAPHITE ]]; then
  echo_log "Enabling Icinga 2 Graphite feature."
  icinga2 feature enable graphite

cat <<EOF >/etc/icinga2/features-enabled/graphite.conf
/**
 * The GraphiteWriter type writes check result metrics and
 * performance data to a graphite tcp socket.
 */

library "perfdata"

object GraphiteWriter "graphite" {
  host = "$ICINGA2_FEATURE_GRAPHITE_HOST"
  port = "$ICINGA2_FEATURE_GRAPHITE_PORT"
}
EOF

fi
