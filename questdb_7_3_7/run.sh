#!/bin/bash

TRIES=3

questdb/bin/questdb.sh stop -t 7_3_7
questdb/bin/questdb.sh start -d /data/qdb_root/questdb_7_3_7 -t 7_3_7
sleep 5

cat queries.sql | while read -r query; do
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches

    echo "$query";
    for i in $(seq 1 $TRIES); do
        curl -sS --max-time 600 -G --data-urlencode "query=${query}" 'http://localhost:19000/exec?timings=true' 2>&1 | grep '"timings"'
        echo
    done;
done;

questdb/bin/questdb.sh stop -t 7_3_7
