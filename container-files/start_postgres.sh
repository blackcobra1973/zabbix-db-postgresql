#!/bin/bash


### Configure zabbix database
/usr/local/bin/zabbix-db-setup.sh

# Start postgres daemon
#exec su postgres -c "/usr/pgsql-9.4/bin/postgres -D /var/lib/pgsql/9.4/data"
supervisord -n

# Update default postgres user password
#exec su postgres -c "psql -c \"alter user postgres password 'password'\";"

