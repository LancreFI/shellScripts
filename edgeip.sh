#!/bin/bash
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
