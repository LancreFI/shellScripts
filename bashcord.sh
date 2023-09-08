#!/bin/bash
##BASIC CONFIG VARIABLES
version="0.1a"
base_url="https://discord.com/api"
#The token should be stored in a file accessible only by the user, so chmod 400 it!
token=$(cat .disco-auth)
auth_header="Bot ${token}"
user_agent="my_c00l_b0t (http://somedoma.in, ${version})"
channel_id="1234123412341234123"
idcounter=0
message_ids=()
user_ids=()
message_list=()
#FOR STORING THE ID OF THE LAST MESSAGE FETCHED
messagefile="/home/username/discord/lastmessage"
if [ ! -f "${messagefile}" ]
then
        echo "0" > "${messagefile}"
fi

last_message=$(cat "${messagefile}")
message='{"content": "'${1}'"}'


function sendMessage() {
        return_response=$(curl -s -X 'POST' \
        -H "Content-Type: application/json" \
        -H "User-Agent: ${user_agent}" \
        -H "Authorization: ${auth_header}" \
        -d "${message}" \
        "${base_url}/channels/${channel_id}/messages")
        echo "${return_response}"
 }


function getMessages() {
        return_response=$(curl -s -X 'GET' \
        -H "Content-Type: application/json" \
        -H "User-agent: ${user_agent}" \
        -H "Authorization: ${auth_header}" \
        "${base_url}/channels/${channel_id}/messages?limit=5")
        echo "${return_response}"
}


messages_json=$(getMessages)
#idlist stores the message- and user ids which is then split to message_ids and user_ids
mapfile -t idlist < <(grep -Po '"id":"\d+"' <<< "${messages_json}" | sed -e 's/^"id":"//' -e 's/"$//')
for id in "${idlist[@]}"
do
        if [[ $((idcounter%2)) -eq 0 ]]
        then
                message_ids+=("${id}")
        else
                user_ids+=("${id}")
        fi
        ((idcounter++))
done

#message list contains the message contents
mapfile -t message_list < <(grep -Po '"content":".*?","channel' <<< "${messages_json}" | sed -e 's/^"content":"//' -e 's/","channel$//')
#author list contains the usernames of the user who posted the messages
mapfile -t author_list < <(grep -Po '"username":".*?","' <<< "${messages_json}" | sed -e 's/^"username":"//' -e 's/","$//')
