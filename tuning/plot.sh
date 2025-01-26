#!/bin/bash

rm ./mydata.txt

for i in $(seq 1 10); do
	echo $i
	uptime | awk '{print $1,$(NF-2),$(NF-1),$NF}' >> ./mydata.txt
	sleep 10
done

gnuplot -p ./plot.gnu
