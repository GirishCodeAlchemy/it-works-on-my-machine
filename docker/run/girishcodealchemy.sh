#!/bin/bash
set -e

show_spinner()
{
  local -r pid="${1}"
  local -r delay='0.2'
  local spinstr='\|/-'
  local temp
  while ps a | awk '{print $1}' | grep -q "${pid}"; do
    temp="${spinstr#?}"
    printf " [%c]  " "${spinstr}"
    spinstr=${temp}${spinstr%"${temp}"}
    sleep "${delay}"
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# First things first, we need to wait for MongoDB to become available, and then we need to make it a master
TIMEOUT=15
wait_for_mongo() {
    for i in `seq $TIMEOUT` ; do
        mongo --host $1 --eval "db.version()" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then
            return
        fi
        sleep 1
    done
    echo "Operation timed out" >&2
    exit 1
}

wait_for_mongo $MONGODB_HOST

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

wait_for vault 8200


#echo "MongoDB: Checking to see if rs.status is ok"
#status=$(mongo --host mongodb --quiet --eval "print(rs.status().ok)")

#if [ $status = '1' ]; then
#    echo "MongoDB: It is already in a replSet, skipping"
#else
#    echo "MongoDB: Initiating ReplSet"
#    mongo --quiet --host mongodb --eval 'rs.initiate({_id: "rs0", members: [{_id: 0, host: "mongodb:27017"}]})'
#fi

#echo "MongoDB: Making sure mongo is master"
# mongo --quiet --host mongodb --eval "while(true) { if (rs.status().ok && db.isMaster().ismaster) { break; } sleep(100) };"

echo "Updating cython modules"
(recompile_zz9_speedups --only-if-needed) > /dev/null  & show_spinner "$!"


echo "MongoDB: Attempting to clear test databases"
mongo --quiet --host $MONGODB_HOST --eval "db.getMongo().getDBNames().forEach(function(dbname) { if (dbname.startsWith('cr-server-')) { print(dbname); db.getMongo().getDB(dbname).dropDatabase()}})"
mongo --quiet --host $MONGODB_HOST --eval "db.getMongo().getDBNames().forEach(function(dbname) { if (dbname.startsWith('cr-lib-tests')) { print(dbname); db.getMongo().getDB(dbname).dropDatabase()}})"
mongo --quiet --host $MONGODB_HOST --eval "db.getMongo().getDBNames().forEach(function(dbname) { if (dbname.startsWith('zz9-')) { print(dbname); db.getMongo().getDB(dbname).dropDatabase()}})"
echo "MongoDB: Initialization is complete"

echo ""

cmd="$@"
if [ -z "$cmd" ]; then
    echo "testrunner <command>"
    echo "Run commands within a testing environments in Docker"
    echo "Available commands:"
    echo "  pytest"
    for i in /code/docker/bin/*; do echo "  `basename $i`"; done
    echo ""
else
    exec $cmd
fi