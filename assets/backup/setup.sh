#!/bin/bash

# setup access to the database in sameersbn/postgresql
echo 'postgresql:5432:*:redmine:password' > /root/.pgpass && chmod 600 /root/.pgpass

# create backup directory
mkdir -p /home/redmine/data/dbbackup/
