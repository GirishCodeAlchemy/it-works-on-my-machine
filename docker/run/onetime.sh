#!/bin/bash

TIMEOUT=15

wait_for() {
  for i in `seq $TIMEOUT` ; do
    nc -z $1 $2 > /dev/null 2>&1

    if [ $? -eq 0 ] ; then
        return
    fi
    sleep 1
  done
  echo "Operation timed out" >&2
  exit 1
}

wait_for mongodb 27017

echo "Checking to see if rs.status is ok"
status=$(mongo --host mongodb --quiet --eval "print(rs.status().ok)")

if [ $status = '1' ]; then
    echo "It is already in a replSet, skipping"
else
    echo "Initiating ReplSet"
    mongo --host mongodb --eval 'rs.initiate({_id: "rs0", members: [{_id: 0, host: "mongodb:27017"}]})'
fi

echo "Waiting for MongoDB to become the master"
mongo --host mongodb --eval "while(true) { if (rs.status().ok && db.isMaster().ismaster) { break; } sleep(100) };"

if [ -f /onetime/.complete ]; then
    echo "Remove the .complete file in the /onetime volume to re-run setup"
    exit 0
fi

echo "Loading fixture data into MongoDB"
mongorestore --host mongodb --port 27017 /mongodump/dump/

echo "Loading fixture data into Postgres"
createdb -h postgres -U postgres zz9_metadata_prod
pg_restore -h postgres -U postgres --clean -d zz9_metadata_prod /pgdump/fntest-postgresdump.sql

touch /onetime/.complete