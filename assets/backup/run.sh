#!/bin/bash

mkdir -p /home/redmine/data/dbbackup/
pg_dump -h postgresql -U redmine redmine_production > /home/redmine/data/dbbackup/dump`/bin/date +%Y%m%d%k%m`.sql