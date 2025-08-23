#!/bin/bash
## SOME AUTOMATION FOR UBIQUITI EDGEROUTER X SFP (MOST LIKELY WORKS
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
target="${2}"

## IF YOU HAVE STATIC/RESERVED IPS FOR THE HOSTS IN YOU LAN
base_address="192.168.12."
targets=(printer server1 server2 naughtykid ps5 iotcrapper)
## YOU CAN ALSO WORK BY USING THE NAME OF THE HOST
## THE HOST IN ARRAY CONTAINS THE LAST IP OCTET OF THE MENTIONED HOST
declare -A address
address["printer"]="33"
address["server1"]="44"
address["server2"]="45"
address["naughtykid"]="66"
address["ps5"]="77"
address["iotcrapper"]="99"

if [[ "${ACTIONS[*]}" =~ "${ACTION^^}" ]]
then
        if [[ "${ACTION^^}" == "BAN" ]]
        then
                action="set"
        else
                action="delete"
        fi
	#LAZY IP VALIDITY CHECK
        if grep -qP "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" <<< "${target}"
        then
                ssh "${USER}@${TARGET}" -p "${PORT}" -i "${IDENTITY}" 'vbash -s' <<-EOF
                source /opt/vyatta/etc/functions/script-template
                configure
                ${action} firewall group address-group "${fwgroup}" address "${target}"
                commit
                save
                exit
                exit
                EOF
	#CHECK FOR VALID NAMED HOST
        elif [[ "${targets[*]}" =~ "${target}" ]]
        then
		#FILL THE BASE ADDRESS WITH THE CORRECT TARGET HOST ADDRESS
                target="${base_address}${address[$target]}"
                ssh "${USER}@${TARGET}" -p "${PORT}" -i "${IDENTITY}" 'vbash -s' <<-EOF
                source /opt/vyatta/etc/functions/script-template
                configure
                ${action} firewall group address-group "${fwgroup}" address "${target}"
                commit
                save
                exit
                exit
                EOF
        else
                echo "### ERRR ###"
                echo " The target ($target) is invalid"
                echo "   Example: bash edge_automate.sh ban 192.168.12.123"
                echo "   Example: bash edge_automate.sh ban naughtykid"
                echo "## ERRRRR ##"
                exit
        fi
else
        echo "### ERRR ###"
        echo " INVALID ACTION: ${ACTION}"
        echo "   Options are: ban, unban"
        echo "   Example: bash edgemate.sh ban 192.168.12.123"
        echo "   Example: bash edgemate.sh ban naughtykid"
        echo "## ERRRRR ##"
fi
