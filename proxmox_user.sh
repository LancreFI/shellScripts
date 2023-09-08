#!/bin/bash
#Your Proxmox IP
proxmox="10.0.0.1"
#The name of your Proxmox node
node="proxmox_nodename"
#Proxmox port
port="8006"
#The ID of the VM you want to control
vmid="123"
api="api2"
#The api-user
api_user="root@pam"
#The ID of the API-token
token_id="vmManager"
#The API key stored in a file that should be only readable by you, so chmod 400 it!
keyfile="/home/username/proxmox/.pm-auth"
if [[ -f "${keyfile}" ]]
then
        token=$(cat "${keyfile}")
else
        echo "MISSING THE API KEY FILE!"
        exit 1
fi
PVEAPIToken="${api_user}!${token_id}=${token}"

function statusCheck()
{
        status_response=$(curl -s -X "GET" -k -H "Authorization: PVEAPIToken=${PVEAPIToken}" \
                        "https://${proxmox}:${port}/${api}/json/nodes/${node}/qemu/${vmid}/status/current")
        status=$(grep -Po "\"status\":\"\w+\"" <<< "${status_response}" | sed -r 's/.*:"(\w+)"/\1/')
        if [[ "${status}" == "" ]]
        then
                echo "The Proxmox server is not responding!"
                exit 1
        else
                echo "${status}"
        fi
}

function restartServer()
{
        curl    -X "POST" -k \
                -H "Authorization: PVEAPIToken=${PVEAPIToken}" \
                "https://${proxmox}:${port}/${api}/json/nodes/${node}/qemu/${vmid}/status/restart"
}

function startServer()
{
        curl    -X "POST" -k \
                -H "Authorization: PVEAPIToken=${PVEAPIToken}" \
                "https://${proxmox}:${port}/${api}/json/nodes/${node}/qemu/${vmid}/status/start"
}

function stopServer()
{
        status_response=$(curl -s -X "POST" -k -H "Authorization: PVEAPIToken=${PVEAPIToken}" \
                "https://${proxmox}:${port}/${api}/json/nodes/${node}/qemu/${vmid}/status/stop")
        echo "${status_response}"
}

#Make the option case insensitive
option="${1^^}"

case "${option}" in
        STATUS)
        statusCheck
        ;;
        START)
        echo "START"
        ;;
        STOP)
        stopServer
        statusCheck
        ;;
        RESTART)
        echo "RESTART"
        ;;
        *)
        echo "The options are: status, start, stop and restart. Choose one!"
        ;;
esac
