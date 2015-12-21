#!/bin/bash

DB_INSTALLED=`sudo -u postgres psql -l | grep -c zabbix`

PG_USER=${PG_USER:="zabbix"}
PG_PASS=${PG_PASS:-$(pwgen -s 12 1)}
PG_DB=${PG_DB:="zabbix"}

if [ $DB_INSTALLED ]
then
  echo "Zabbix Database already exists, nothing to do in this script"
  exit 0
fi

echo "Zabbix Database creation"
echo "  Creating Role/User: ${PG_USER} with Password: ${PG_PASS}"
sudo -u postgres psql -c "CREATE ROLE ${PG_USER} WITH SUPERUSER LOGIN PASSWORD '${PG_PASS}';"
sudo -u postgres psql -c "CREATE DATABASE ${PG_DB} WITH OWNER = '${PG_USER}';"

echo "  Populating the Database: ${PG_DB}"
sudo -u postgres psql -U ${PG_USER} -d ${PG_DB} -f /tmp/schema.sql
sudo -u postgres psql -U ${PG_USER} -d ${PG_DB} -f /tmp/images.sql
sudo -u postgres psql -U ${PG_USER} -d ${PG_DB} -f /tmp/data.sql

echo "  Activating table partitioning on Database: ${PG_PASS}"
sudo -u postgres psql -U ${PG_USER} -d ${PG_DB} -f /usr/local/tmp/zabbix_sql/01_create_partitions_schema.sql
sudo -u postgres psql -U ${PG_USER} -d ${PG_DB} -f /usr/local/tmp/zabbix_sql/02_create_main_function.sql
sudo -u postgres psql -U ${PG_USER} -d ${PG_DB} -f /usr/local/tmp/zabbix_sql/03_create_triggers_for_tables.sql
sudo -u postgres psql -U ${PG_USER} -d ${PG_DB} -f /usr/local/tmp/zabbix_sql/04_create_remove_functions.sql

