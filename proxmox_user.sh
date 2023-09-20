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
#The VMs the user's API key is attached to, vmid as the index number
#You need to check the vm ids from Proxmox, the name is just to make things easier for the user
vmids[101]="apache2"
vmids[201]="pfsense"
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
        vmid="${2}"
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

#The first parameter to lowercase (only if your vm names in the vmids array is lowercase, 
#otherwise adjust accordingly)
destination_vm="${1,,}"
counter=0

if [[ "${destination_vm}" == "-h" ]] || [[ "${destination_vm}" == "--help" ]]
then
        vmnames=""
        for vm in "${vmids[@]}"
        do
                vmnames+="    -$vm\n"
        done

        echo "######################################################################"
        echo ""
        echo "  Usage: bash proxmox_user.sh <vmname> <status|start|stop|restart>"
        echo ""
        echo "  Available vmnames:"
        printf "${vmnames}"
        echo ""
        echo "######################################################################"
else

        for vm in "${!vmids[@]}"
        do
                if [[ "${vmids[${vm}]}" == "${destination_vm}" ]]
                then
                        destination_vm="${vm}"
                        ((counter++))
                fi
        done
        if [ "${counter}" -ne 1 ]
        then
                echo "No target vm found with the name: ${1}"
                exit
        fi

        option="${2^^}"
        case "${option}" in
                STATUS)
                vmTask "status" "${destination_vm}"
                ;;
                START)
                vmTask "start" "${destination_vm}"
                ;;
                STOP)
                vmTask "stop" "${destination_vm}"
                ;;
                RESTART)
                vmTask "reboot" "${destination_vm}"
                ;;
                *)
                echo "Missing the action: status/start/stop/restart"
                ;;
        esac
fi
