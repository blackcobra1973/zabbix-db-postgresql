zabbix-db-postgresql
====================

Dockerfile to build PostgreSQL on CentOS 7

Features added:

- Zabbix DB for version 3.x
- PostgreSQL automatic table partitioning for Zabbix

Setup
-----

To build the image

    # docker build --rm -t <yourname>/zabbix-db-postgresql .

Launching PostgreSQL
--------------------

#### Quick Start (not recommended for production use)

    docker run --name=postgresql -d <yourname>/zabbix-db-postgresql


To connect to the container as the administrative `postgres` user:

    docker run -it --rm --volumes-from=postgresql <yourname>/zabbix-db-postgresql sudo -u
    postgres -H psql

Creating a database at launch
-----------------------------

You can create a postgresql superuser at launch by specifying `DB_USER` and
`DB_PASS` variables. You may also create a database by using `DB_NAME`.

    docker run --name postgresql -d \
    -e 'DB_USER=username' \
    -e 'DB_PASS=ridiculously-complex_password1' \
    -e 'DB_NAME=my_database' \
    <yourname>/zabbix-db-postgresql

When you want to use a data container run the following command:

    docker run --name postgresql -d \
    --volumes-from pgdata \
    -e 'DB_USER=username' \
    -e 'DB_PASS=ridiculously-complex_password1' \
    -e 'DB_NAME=my_database' \
    <yourname>/zabbix-db-postgresql

To connect to your database with your newly created user:

    psql -U username -h $(docker inspect --format {{.NetworkSettings.IPAddress}} postgresql)
