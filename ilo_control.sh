#!/bin/bash
ilo_ip="10.10.10.10"
ilo_port="8006"
## The netrc -file used by curl is defined here, the file content should be:
## machine <ip-address> login <user_with_valid_account_on_ilo> password <the user's iLO password>
## machine 10.10.10.10 login ilo_apiuser password qptlOxR?mtnA#n^Bv9C!R:ZC
## remember to chmod 400 the file for minimal access
credentials="/home/user/.iloauth"
option="${1^^}"

function statusCheck()
{
        response_full=$(curl -s --netrc-file "${credentials}" "https://${ilo_ip}:${ilo_port}/redfish/v1/systems/1/" -k -w "%{http_code}")
        response_code=$(grep -Po "^\d{3}$" <<< "${response_full}")
        ##You could get the JSON only response with this:
        ##response_json=$(grep -vP "^\d{3}$" <<< "${response_full}")
        status=$(grep -Po '"PowerState":"\w+' <<< "${response_full}" | sed 's/"PowerState":"//g')
}

function powerControl()
{
        allowed_actions=("On" "PushPowerButton")
        action="${1}"
        if [[ "${allowed_actions[@]}" =~ "${action}" ]]
        then
                power_response=$(curl -k -s --netrc-file "${credentials}" \
                -X "POST" "https://${ilo_ip}:${ilo_port}/redfish/v1/systems/1/Actions/ComputerSystem.Reset/" \
                -H "Content-Type: application/json" \
                -d "{ \"ResetType\": \"${action}\" }")
        else
                echo "Unknown action ${action}"
        fi
}

statusCheck
if [ "${response_code}" -eq "200" ]
then
        wait_counter=0
        case "${option}" in
                STATUS)
                        echo "Server status: ${status}"
                ;;
                START)
                        if [[ "${status}" != "On" ]]
                        then
                                echo "Starting up the server"
                                powerControl "On"
                                while [[ "${status}" != "Off" ]]
                                do
                                        if [[ "${wait_counter}" -eq 12 ]]
                                        then
                                                echo "Wait limit reached, contact admin"
                                                exit 1
                                        fi
                                        statusCheck
                ;;
                STOP)
                        if [[ "${status}" != "Off" ]]
                        then
                                echo "Shutting down the server"
                                powerControl "PushPowerButton"
                                while [[ "${status}" != "Off" ]]
                                do
                                        if [[ "${wait_counter}" -eq 12 ]]
                                        then
                                                echo "Wait limit reached, contact admin"
                                                exit 1
                                        fi
                                        statusCheck
                                        sleep 5
                                        ((wait_counter++))
                                done
                                echo "Server shutdown completed"
                        else
                                echo "The server is already switched off"
                        fi
                ;;
                RESTART)
                        if [[ "${status}" == "On" ]]
                        then
                                echo "Shutting down the server"
                                powerControl "PushPowerButton"
                                while [[ "${status}" != "Off" ]]
                                do
                                        if [[ "${wait_counter}" -eq 12 ]]
                                        then
                                                echo "Wait limit reached, contact admin"
                                                exit 1
                                        fi
                                        statusCheck
                                        sleep 5
                                        ((wait_counter++))
                                done
                                wait_counter=0
                                echo "Server shutdown completed"
                                sleep 2
                                echo "Bringing the server back up"
                                powerControl "On"
                                while [[ "${status}" != "On" ]]
                                do
                                        if [[ "${wait_counter}" -eq 12 ]]
                                        then
                                                echo "Wait limit reached, contact admin"
                                                exit 1
                                        fi
                                        statusCheck
                                        sleep 5
                                        ((wait_counter++))
                                done
                                echo "Restart complete"
                        else
                                echo "The server was already off, restarting"
                                powerControl "On"
                                while [[ "${status}" != "On" ]]
                                do
                                        if [[ "${wait_counter}" -eq 12 ]]
                                        then
                                                echo "Wait limit reached, contact admin"
                                                exit 1
                                        fi
                                        statusCheck
                                        sleep 5
                                        ((wait_counter++))
                                done
                                echo "Restart complete"
                        fi
                ;;
                *)
                        echo "Unknown option"
                ;;
        esac
else
        echo "iLO request failed! Response: ${response_code}"
fi
