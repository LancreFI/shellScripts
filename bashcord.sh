#!/bin/bash
##Somekind of a bash/curl bot for your Discord channel
##Create the bot as administrator for the channel, to get it working the easiest :D
version="0.1a"
base_url="https://discord.com/api"
#The token is storen in a file accessible only by the user
token=$(cat .auth)
auth_header="Bot ${token}"
user_agent="my_c00l_b0t (http://somedoma.in, ${version})"
channel_id="1234123412341234123"
message='{"content": "'${1}'"}'

function sendMessage() {
        curl -X 'POST' \
        -H "Content-Type: application/json" \
        -H "User-Agent: ${user_agent}" \
        -H "Authorization: ${auth_header}" \
        -d "${message}" \
        "${base_url}/channels/${channel_id}/messages"
 }

function getMessages() {
        curl -X 'GET' \
        -H "Content-Type: application/json" \
        -H "User-agent: ${user_agent}" \
        -H "Authorization: ${auth_header}" \
        "${base_url}/channels/${channel_id}/messages?limit=100"
}
