#!/bin/sh

URL=http://localhost:8080/config
ITERATIONS=1000

rm $1

for i in $(seq $ITERATIONS)
do
  curl $URL -w "%{time_connect},%{time_total},%{speed_download},%{http_code},%{size_download},%{url_effective}\n" -o /dev/null -s >> $1
done
