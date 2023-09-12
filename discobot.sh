#!/bin/bash
##BASIC CONFIG VARIABLES
version="0.1a"
base_url="https://discord.com/api"
#The token should be stored in a file accessible only by the user, so chmod 400 it!
token=$(cat .disco-auth)
auth_header="Bot ${token}"
user_agent="my_c00l_b0t (http://somedoma.in, ${version})"
channel_id="1234123412341234123"
id_counter=0
last_message_cell=0
message_counter=0
message_ids=()
user_ids=()
message_list=()
#For storing the ID of last message fetched
message_file="/home/username/discord/lastmessage"
if [ ! -f "${message_file}" ]
then
        echo "0" > "${message_file}"
fi
last_message_id=$(cat "${message_file}")
#For managing a Proxmox vm
vmcontrol="/home/username/discord/proxmox_user.sh"
if [ ! -f "${vmcontrol}" ]
then
        echo "Missing the script to control vms"
        exit
fi
#The Discord user ID of the person to mention if API not responding
server_admin="123456789012345678"


function sendMessage() {
        message='{"content": "'${1}'"}'
        return_response=$(curl -s -X 'POST' \
        -H "Content-Type: application/json" \
        -H "User-Agent: ${user_agent}" \
        -H "Authorization: ${auth_header}" \
        -d "${message}" \
        "${base_url}/channels/${channel_id}/messages")
 }


##Change the limit of messages to get on the last curl row if needed
function getMessages() {
        return_response=$(curl -s -X 'GET' \
        -H "Content-Type: application/json" \
        -H "User-agent: ${user_agent}" \
        -H "Authorization: ${auth_header}" \
        "${base_url}/channels/${channel_id}/messages?limit=20")
        echo "${return_response}"
}


function checkTriggers() {
        checkmsg="${1}"
        trigged=0
        action=""
        #Trigger messages on the channel
        triggers=("!server-status" "!server-start" "!server-stop" "!server-reboot")
        for trigger in "${triggers[@]}"
        do
                if grep -qo "^${trigger}" <<< "${checkmsg}"
                then
                        ((trigged++))
                        action=$(cut -d "-" -f 2 <<< "${trigger}")
                        break
                fi
        done

        if [ "${trigged}" -gt 0 ]
        then
                vmresponse=$(bash "${vmcontrol}" "${action}")
                if [[ "${vmresponse}" == "error" ]]
                then                                                  
                        sendMessage "Server not responding, pinging <@${server_admin}>"
                elif [[ "${action}" == "status" ]]
                then
                        sendMessage "Server ${action}: ${vmresponse}"
                else
                        sendMessage "Server ${vmresponse}!"
                fi
        fi
}

messages_json=$(getMessages)
mapfile -t id_list < <(grep -Po '"id":"\d+"' <<< "${messages_json}" | sed -e 's/^"id":"//' -e 's/"$//')
mapfile -t message_list < <(grep -Po '"content":".*?","channel' <<< "${messages_json}" | sed -e 's/^"content":"//' -e 's/","channel$//')
mapfile -t author_list < <(grep -Po '"username":".*?","' <<< "${messages_json}" | sed -e 's/^"username":"//' -e 's/","$//')


#The most recent message is first
for id in "${id_list[@]}"
do
        if [[ $((id_counter%2)) -eq 0 ]]
        then
                #Get the last message array cell number that contains a new message, except if they are all new
                if [[ "${id}" == "${last_message_id}" ]]
                then
                        #If the latest message is the same as last time...
                        if [ "${id_counter}" -gt "0" ]
                        then
                                last_message_cell=$((id_counter/2-1))
                                ((id_counter++))
                                user_ids+=("${id_list[$id_counter]}")
                                message_counter="${last_message_cell}"
                                message_ids+=("${id}")
                        else
                                last_message_id="-1"
                        fi
                        #we need to skip everything
                        break
                fi
                message_ids+=("${id}")
        else
                user_ids+=("${id}")
        fi
        ((id_counter++))
done

#All messages are new
if [[ "${last_message_id}" == "0" ]]
then
        last_message_cell=$((${#message_ids[@]}-1))
        message_counter="${last_message_cell}"
#No new messages
elif [ "${last_message_id}" == "-1" ]
then
        echo "No new messages"
        exit
fi
#Save the last message's ID
echo "${message_ids[0]}" > "${message_file}"

for message in "${message_list[@]}"
do
        if [ "${message_counter}" -ge "0" ]
        then
                checkTriggers "${message_list[${message_counter}]}"
                ((message_counter--))
        fi
done
