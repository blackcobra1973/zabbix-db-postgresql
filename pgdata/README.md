zabbix-postgresql-data
======================

Dockerfile to build persistent data container for Zabbix PostgreSQL on CentOS 7

Setup
-----

To build the image

    # docker build --rm -t zabbix-postgresql-data .

Launching PostgreSQL
--------------------

#### Quick Start

    # docker run --name pgdata zabbix-postgresql-data
