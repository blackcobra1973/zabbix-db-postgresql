#!/bin/bash
echo "******CREATING ZABBIX DATABASE******"

DB_NAME=${DB_NAME:="zabbix"}
DB_USER=${DB_USER:="zabbix"}
DB_PASS=${DB_PASS:-}
PG_CONFDIR="/var/lib/pgsql/${PG_Version}/data"
PG_BINDIR="/usr/pgsql-${PG_Version}/bin"

echo "starting postgres"
sudo -u postgres $PG_BINDIR/pg_ctl -w start

DB_INSTALLED=`sudo -u postgres psql -l | grep -c zabbix`

if [ $DB_INSTALLED ]
then
  echo "Zabbix Database already exists, nothing to do in this script"
  echo "stopping postgres"
  sudo -u postgres $PG_BINDIR/pg_ctl stop
  echo "stopped postgres"
  exit 0
fi

echo "Zabbix Database creation"
#Grant rights
usermod -G wheel postgres

# Check to see if we have pre-defined credentials to use
if [ -n "${DB_USER}" ]; then
  if [ -z "${DB_PASS}" ]; then
    echo ""
    echo "WARNING: "
    echo "No password specified for \"${DB_USER}\". Generating one"
    echo ""
    DB_PASS=$(pwgen -c -n -1 12)
    echo "Password for \"${DB_USER}\" created as: \"${DB_PASS}\""
  fi
  echo "  Creating Role/User: ${DB_USER} with Password: ${DB_PASS}"
  sudo -u postgres psql -c "CREATE ROLE ${DB_USER} WITH CREATEROLE SUPERUSER LOGIN PASSWORD '${DB_PASS}';"
fi

if [ -n "${DB_NAME}" ]; then
  echo "Creating database \"${DB_NAME}\"..."
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} WITH OWNER ='${DB_USER}' ENCODING='UTF8' lc_collate='en_US.UTF-8' lc_ctype='en_US.UTF-8' ;"
fi
if [ -n "${DB_USER}" ]; then
  echo "Granting access to database \"${DB_NAME}\" for user \"${DB_USER}\"..."
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} to ${DB_USER};"
fi

echo "  Populating the Database: ${DB_NAME}"
sudo -u postgres psql -U ${DB_USER} -d ${DB_NAME} -f /tmp/schema.sql
sudo -u postgres psql -U ${DB_USER} -d ${DB_NAME} -f /tmp/images.sql
sudo -u postgres psql -U ${DB_USER} -d ${DB_NAME} -f /tmp/data.sql

echo "  Activating table partitioning on Database: ${DB_NAME}"
sudo -u postgres psql -U ${DB_USER} -d ${DB_NAME} -f /usr/local/tmp/zabbix_sql/01_create_partitions_schema.sql
sudo -u postgres psql -U ${DB_USER} -d ${DB_NAME} -f /usr/local/tmp/zabbix_sql/02_create_main_function.sql
sudo -u postgres psql -U ${DB_USER} -d ${DB_NAME} -f /usr/local/tmp/zabbix_sql/03_create_triggers_for_tables.sql
sudo -u postgres psql -U ${DB_USER} -d ${DB_NAME} -f /usr/local/tmp/zabbix_sql/04_create_remove_functions.sql

echo "stopping postgres"
sudo -u postgres $PG_BINDIR/pg_ctl stop
echo "stopped postgres"
