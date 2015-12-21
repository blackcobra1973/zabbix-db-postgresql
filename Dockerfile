#Author:KD

FROM centos:centos7
MAINTAINER Kurt Dillen <kurt.dillen@dls-belgium.com>

RUN yum -y update; yum clean all
RUN yum -y install sudo epel-release; yum clean all

#Sudo requires a tty. fix that.
RUN sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers

# Install pgdg repo for getting new postgres RPMs
RUN rpm -ivh http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-1.noarch.rpm

# Install Postgres Version 9.4
RUN yum install postgresql94-server postgresql94 postgresql94-contrib postgresql94-plperl postgresql94-devel -y --nogpgcheck; yum clean all

# Modified setup script to bypass systemctl variable read stuff
ADD ./container-files/postgresql94-setup /usr/pgsql-9.4/bin/postgresql94-setup

# Update data folder perms
RUN chown -R postgres.postgres /var/lib/pgsql

#Modify perms on setup script
RUN chmod +x /usr/pgsql-9.4/bin/postgresql94-setup

#Initialize data for pg engine
RUN sh /usr/pgsql-9.4/bin/postgresql94-setup initdb

#Access from all over --- NEVER DO THIS SHIT IN POST DEV ENVs !!!!!!!!!!!!!!!!!!! <--- READ THIS
ADD ./container-files/etc/postgresql/postgresql.conf /var/lib/pgsql/9.4/data/postgresql.conf
ADD ./container-files/etc/postgresql/pg_hba.conf /var/lib/pgsql/9.4/data/pg_hba.conf

#Add start script for postgres
ADD ./container-files/start_postgres.sh /start_postgres.sh

RUN chmod +x /start_postgres.sh

VOLUME ["/var/lib/pgsql"]

EXPOSE 5432

#Run pgEngine
CMD ["/start_postgres.sh"]
