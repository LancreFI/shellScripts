#!/bin/bash
HOST="$1"

if [ "$HOST" == "" ]
then
        echo ".-------------------------------------------------------."
        echo "| Requires: wget                                        |"
        echo "+-------------------------------------------------------+"
        echo "| USAGE:    bash well-known.sh http/https://host.name   |"
        echo "+-------------------------------------------------------+"
        echo "| Example:  bash well-known.sh http://target.host       |"
        echo "'-------------------------------------------------------'"
else

        WELL=(acme-challenge ashrae assetlinks.json caldav carddav coap \
        core csvm dnt dnt-policy.txt est genid hoba host-meta host-meta.json \
        http-opportunistic keybase.txt mercure mta-sts.txt ni openid-configuration \
        openorg pki-validation posh reload-config repute-template resourcesync \
        security.txt stun-key time timezone uma2-configuration void webfinger \
        apple-app-site-association apple-developer-merchantid-domain-association \
        browserid openpgpkey autoconfig/mail change-password nodeinfo)

        echo ".-------------------------------------------------------."
        echo "|    Checking for .well-known/files...                  |"
        echo "+-------------------------------------------------------+"

        for wk in "${WELL[@]}"
        do
                if wget --spider "$HOST/.well-known/$wk" 2>/dev/null
                then
                        echo "|> $wk FOUND!"
                fi
        done
        echo "+-------------------------------------------------------+"
        echo "|                       DONE                            |"
        echo "'-------------------------------------------------------'"
fi
