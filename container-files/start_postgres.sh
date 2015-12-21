#!/bin/bash

# Start postgres daemon
exec su postgres -c "/usr/pgsql-9.4/bin/postgres -D /var/lib/pgsql/9.4/data"

# Update default postgres user password
#exec su postgres -c "psql -c \"alter user postgres password 'password'\";"

exec /usr/local/bin/zabbix-db-setup.sh
