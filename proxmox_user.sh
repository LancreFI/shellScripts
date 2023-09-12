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


function vmTask()
{
        task="${1}"
        method=""

        if [[ "${task}" == "status" ]]
        then
                method="GET"
                status_response=$(curl -s -X "$method" -k -H "Authorization: PVEAPIToken=${PVEAPIToken}" \
                        "https://${proxmox}:${port}/${api}/json/nodes/${node}/qemu/${vmid}/status/current")
                status=$(grep -Po "\"status\":\"\w+\"" <<< "${status_response}" | sed -r 's/.*:"(\w+)"/\1/')
        else
                method="POST"
                status_response=$(curl -s -X "$method" -k -H "Authorization: PVEAPIToken=${PVEAPIToken}" \
                        "https://${proxmox}:${port}/${api}/json/nodes/${node}/qemu/${vmid}/status/${task}")
                if grep -qPo "qm${task}" <<< "${status_response}"
                then
                        if [[ "${task}" == "stop" ]]
                        then
                                status="${task}ped"
                        else
                                status="${task}ed"
                        fi
                fi
        fi

        if [[ "${status}" == "" ]]
        then
                echo "error"
                exit 1
        else
                echo "${status}"
        fi
}

#Make the option case insensitive
option="${1^^}"

case "${option}" in
        STATUS)
        vmTask "status"
        ;;
        START)
        vmTask "start"
        ;;
        STOP)
        vmTask "stop"
        ;;
        RESTART)
        vmTask "reboot"
        ;;
        *)
        echo "CRAP"
        ;;
esac
