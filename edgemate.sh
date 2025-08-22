#!/bin/bash
## SOME AUTOMATION FOR UBIQITI EDGEROUTER X SFP (MOST LIKELY WORKS
## IN MOST VYOS ENVS ANYWAY)
## THIS USES SSH PUBLIC KEY AUTH WITH NO PW
IDENTITY="/home/USER/.ssh/masterkey"
## SO FAR ONLY FOR FIREWALL BLOCK/UNBLOCK USING A FIREWALL GROUP
## REMEMBER TO CREATE THE FIREWALL GROUP BEFORE HAND
fwgroup="banneds"
## I ALSO HAVE AN AUTOMATION SCRIPT TO UPDATE MY ROUTER IP WHEN IT
## CHANGES AND SAVE IT ON THIS HOST IN THIS PATH
TARGET=$(cat "/home/USER/public_ip/current_ip")
PORT="15517"
USER="username"
ACTIONS=(BAN UNBAN)
ACTION="${1}"
ip="${2}"

if [[ "${ACTIONS[*]}" =~ "${ACTION^^}" ]]
then
	#A LAZY IP VALIDITY CHECK
        if grep -qP "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" <<< "${IP}"
        then
                if [[ "${ACTION^^}" == "BAN" ]]
                then
                        action="set"
                else
                        action="delete"
                fi
                ssh "${USER}@${TARGET}" -p "${PORT}" -i "${IDENTITY}" 'vbash -s' <<-EOF
                source /opt/vyatta/etc/functions/script-template
                configure
                ${action} firewall group address-group "${fwgroup}" address "${customip}"
                commit
                save
                exit
                exit
                EOF
        else
                echo "The IP ${ip} is invalid"
                echo "Example: bash edge_automate.sh ban 192.168.12.123"
                exit
        fi
else
        echo "INVALID ACTION: ${ACTION}"
        echo "Options are: ban, unban"
        echo "Example: bash edge_automate.sh ban 192.168.12.123"
fi
