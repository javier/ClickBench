#!/bin/bash

# Install

#wget https://github.com/questdb/questdb/releases/download/7.3.7/questdb-7.3.7-rt-linux-amd64.tar.gz
#tar xf questdb*.tar.gz --one-top-level=questdb --strip-components 1
#questdb/bin/questdb.sh start -d /data/qdb_root/questdb_7_3_7 -t 7_3_7

#while ! nc -z localhost 19000; do
#  sleep 0.1
#done

#sed -i 's/query.timeout.sec=60/query.timeout.sec=500/' ~/.questdb/conf/server.conf
#sed -i "s|cairo.sql.copy.root=import|cairo.sql.copy.root=$PWD|" ~/.questdb/conf/server.conf
#questdb/bin/questdb.sh stop -t 7_3_7
#questdb/bin/questdb.sh start -d /data/qdb_root/questdb_7_3_7 -t 7_3_7

# Import the data

#wget --no-verbose --continue 'https://datasets.clickhouse.com/hits_compatible/hits.csv.gz'
#gzip -d hits.csv.gz

#curl -G --data-urlencode "query=$(cat create.sql)" 'http://localhost:19000/exec'

# SQL COPY works best on metal instances:
#curl -G --data-urlencode "query=copy hits from 'hits.csv' with timestamp 'EventTime' format 'yyyy-MM-dd HH:mm:ss';" 'http://localhost:19000/exec'

#echo 'waiting for import to finish...'
#until [ "$(curl -s -G --data-urlencode "query=select * from sys.text_import_log where phase is null and status='finished';" 'http://localhost:19000/exec' | grep -c '"count":1')" -ge 1 ]; do
#    echo '.'
#    sleep 5
#done

#curl -s -G --data-urlencode "query=select datediff('s', start, finish) took_secs from (select min(ts) start, max(ts) finish from sys.text_import_log where phase is null);" 'http://localhost:19000/exec'

# On smaller instances use this:
# start=$(date +%s)

# curl -F data=@hits.csv 'http://localhost:19000/imp?name=hits'

# echo 'waiting for rows to become readable...'
# until [ "$(curl -s -G --data-urlencode "query=select 1 from (select count() c from hits) where c = 99997497;" 'http://localhost:19000/exec' | grep -c '"count":1')" -ge 1 ]; do
#     echo '.'
#     sleep 1
# done

# end=$(date +%s)
# echo "import took: $(($end-$start)) secs"

# Run queries

./run.sh 2>&1 | tee log.txt


data_size=$(du -bcs /data/qdb_root/questdb_7_3_7/db/hits* | awk 'NR==1 {print $1}')


results=`cat log.txt | grep -P '"timings"|"error"|null' | sed -r -e 's/^.*"error".*$/null/; s/^.*"execute":([0-9]*),.*$/\1/' |
  awk '{ print ($1) / 1000000000 }' | sed -r -e 's/^0$/null/' |
  awk '{ if (i % 3 == 0) { printf "[" }; printf $1; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }'`


# Remove the very last comma of the `results` variable
results=${results::-1}
current_date=$(date +"%Y-%m-%d")

echo "{
    \"system\": \"QuestDB 7_3_7\",
    \"date\": \"$current_date\",
    \"machine\": \"m6a.4xlarge, 250gb gp3 ZFS\",
    \"cluster_size\": 1,
    \"comment\": \"Uses multi-threaded COPY SQL for data load.\",
    \"tags\": [\"Java\", \"time-series\"],
    \"load_time\": 0,
    \"data_size\": $data_size,
    \"result\": [
    $results
    ]
}" > results/m6a.4xlarge.7_3_7.json

cat results/m6a.4xlarge.7_3_7.json

