#!/bin/bash
logfile="/home/username/unturned/unturned_serverlog.log"
counter=0
while [[ ! $(tail -1 "${logfile}" | grep "Loading level: 100%" "${logfile}") ]]
do
        if [[ "${counter}" -eq 30 ]]
        then
                echo "ERR"
                exit
        fi
        sleep 5
        ((counter++))
done

server_code=$(grep "Server Code: " "${logfile}" | sed 's/://')
echo "${server_code,,}"
