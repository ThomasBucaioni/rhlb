#!/bin/bash

# Tell bash to exit after SIGINT
trap "exit" INT

# Write a 100Mb file every loop
while true; do
	dd if=/dev/zero of=100MBfile bs=510 count=200000 oflag=dsync
done


