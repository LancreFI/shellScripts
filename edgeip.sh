#!/bin/bash
## READS THE IP OF YOUR WAN INTERFACE, IN THIS ETH0
## UPDATES IT TO A FILE AND THEN SFTP'S IT OVER KEY
## AUTH WITH NO PASS TO EXTERNAL HOST WHICH IN TURN
## DOES WHATEVER MAGIC YOU NEED WITH THE IP
## JUST PUT THIS IN YOUR ROOT CRONTAB ON YOUR UBIQITI
## EDGEROUTER X SFP, MOST LIKELY WORKS WITH OTHERS TOO
PREVIOUS_IP_FILE="/home/USER/current_ip"
PREVIOUS_IP=$(cat "${PREVIOUS_IP_FILE}")
IP=$(ip add show eth0 | grep -o "inet.*brd" | grep -oP "\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b")
if [[ "${IP}" != "${PREVIOUS_IP}" ]]
then
        echo "${IP}" > "${PREVIOUS_IP_FILE}"
sftp -i /home/USER/.ssh/id_rsa USER@HOST.TLD << EOF
cd public_ip
put current_ip
EOF
fi
