#Author:KD

FROM centos:centos7
MAINTAINER Kurt Dillen <kurt.dillen@dls-belgium.com>

ENV \
  PG_Version=9.5 \
  PGSETUP_INITDB_OPTIONS="-E UTF8 --locale='en_US.UTF-8'" \
  DEBUG=1

RUN echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
RUN export LANG=en_US.UTF-8

RUN \
    yum -y update && \
    yum -y install epel-release && \
    rpm -ivh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm && \
    yum -y install sudo pwgen bind-utils bzip2 supervisor psmisc && \
    yum install postgresql95-server postgresql95 postgresql95-contrib postgresql95-plperl postgresql95-devel -y --nogpgcheck && \
    yum clean all

ADD ./container-files/supervisord.conf /etc/supervisord.conf

#Sudo requires a tty. fix that.
RUN sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers

# Update data folder perms
RUN chown -R postgres.postgres /var/lib/pgsql

# Modified setup script to bypass systemctl variable read stuff
ADD ./container-files/postgresql95-setup /usr/pgsql-9.5/bin/postgresql95-setup

#Modify perms on setup script
RUN chmod +x /usr/pgsql-9.5/bin/postgresql95-setup

#Initialize data for pg engine
RUN sh /usr/pgsql-9.5/bin/postgresql95-setup initdb

### Default PostgreSQL configuration files
ADD ./container-files/etc/postgresql/postgresql.conf /var/lib/pgsql/9.5/data/postgresql.conf
ADD ./container-files/etc/postgresql/pg_hba.conf /var/lib/pgsql/9.5/data/pg_hba.conf

#Add start script for postgres
ADD ./container-files/start_postgres.sh /start_postgres.sh
RUN chmod +x /start_postgres.sh

## Add Zabbix related files
RUN mkdir -p /usr/local/tmp/zabbix_sql
ADD ./container-files/sql/* /usr/local/tmp/zabbix_sql/
ADD ./container-files/zabbix/* /tmp/

VOLUME ["/var/lib/pgsql"]
EXPOSE 5432

#Run pgEngine
CMD ["/start_postgres.sh"]
