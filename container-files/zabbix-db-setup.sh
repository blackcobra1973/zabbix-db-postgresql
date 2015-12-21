#!/bin/bash

DB_INSTALLED=`sudo -u postgres psql -l | grep -c zabbix`

if [ $DB_INSTALLED ]
then
  echo "Zabbix Database already exists, nothing to do in this script"
  exit 0
fi
