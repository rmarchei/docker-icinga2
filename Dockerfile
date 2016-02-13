# Icinga2
#
#

FROM centos:latest
MAINTAINER Ruggero Marchei <ruggero.marchei@daemonzone.net>

RUN yum -y install http://packages.icinga.org/epel/7/release/noarch/icinga-rpm-release-7-1.el7.centos.noarch.rpm \
  && yum install -y epel-release \
  # docs are not installed by default https://github.com/docker/docker/issues/10650 https://registry.hub.docker.com/_/centos/
  # official docs are wrong, go for http://superuser.com/questions/784451/centos-on-docker-how-to-install-doc-files
  # we'll need that for mysql schema import for icingaweb2
  && ( [ -f /etc/rpm/macros.imgcreate ] && sed -i '/excludedocs/d' /etc/rpm/macros.imgcreate || exit 0 ) \
  && ( [ -f /etc/yum.conf ] && sed -i '/nodocs/d' /etc/yum.conf || exit 0 ) \
  && yum install -y supervisor openssh-clients mailx httpd mod_ssl openssl mariadb-server pwgen \
  && yum install -y icinga2 icinga2-doc icinga2-ido-mysql icingaweb2 icingacli nagios-plugins-all hp-ZendFramework php-ZendFramework-Db-Adapter-Pdo-Mysql psmisc iproute \
  && yum clean all -q

ADD content/ /
RUN chmod u+x /docker-entrypoint.sh

# fixes at build time (we can't do that at user's runtime)
# setuid problem https://github.com/docker/docker/issues/6828
# 4755 ping is required for icinga user calling check_ping
# can be circumvented for icinga2.cmd w/ mkfifo and chown
# (icinga2 does not re-create the file)
RUN mkdir -p /var/log/supervisor; \
 chmod 4755 /bin/ping /bin/ping6; \
 chown -R icinga:root /etc/icinga2; \
 mkdir -p /etc/icinga2/pki; \
 chown -R icinga:icinga /etc/icinga2/pki; \
 mkdir -p /var/run/icinga2; \
 mkdir -p /var/log/icinga2; \
 chown icinga:icingacmd /var/run/icinga2; \
 chown icinga:icingacmd /var/log/icinga2; \
 mkdir -p /var/run/icinga2/cmd; \
 mkfifo /var/run/icinga2/cmd/icinga2.cmd; \
 chown -R icinga:icingacmd /var/run/icinga2/cmd; \
 chmod 2750 /var/run/icinga2/cmd; \
 chown -R icinga:icinga /var/lib/icinga2; \
 usermod -a -G icingacmd apache >> /dev/null; \
 chown root:icingaweb2 /etc/icingaweb2; \
 chmod 2770 /etc/icingaweb2; \
 mkdir -p /etc/icingaweb2/enabledModules; \
 chown -R apache:icingaweb2 /etc/icingaweb2/*; \
 find /etc/icingaweb2 -type f -name "*.ini" -exec chmod 660 {} \; ; \
 find /etc/icingaweb2 -type d -exec chmod 2770 {} \;

# configure PHP timezone
RUN sed -i 's/;date.timezone =/date.timezone = UTC/g' /etc/php.ini

# ports (icinga2 api & cluster (5665), mysql (3306))
EXPOSE 22 80 443 5665 3306

# volumes
VOLUME ["/etc/icinga2", "/etc/icingaweb2", "/var/lib/icinga2", "/usr/share/icingaweb2", "/var/lib/mysql"]

# change this to entrypoint preventing bash login
CMD ["/docker-entrypoint.sh"]
#ENTRYPOINT ["/opt/icinga2/initdocker"]
