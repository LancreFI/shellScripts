#!/bin/bash
USER="ubuntu"
PRECEIVER="/home/$USER/pinger/preceiver.sh"
CRONFILE="/home/$USER/pinger/cronfile"
PINGDUMP="/home/$USER/pinger/pingdump"
EXTRACTOR="/home/$USER/pinger/pextract.sh"
CONLOG="/home/$USER/pinger/conlog"
START=$(cat $PINGDUMP | grep --max-count=1 -o "beef 15f0 0d11" | sed -e 's/ 15f0 0d11//')

if [ ! -z ${START} ]
then
        echo "NEW PING-CONTENT FOUND AT" $(date +%d"."%m"."%Y"_"%H":"%M"(UTC0)") >> $CONLOG
        END=$(cat $PINGDUMP | grep --max-count=1 -o "dead beef" | sed -e 's/ beef//')
        if [ ! -z "${END}" ]
        then
                PID=$(ps -u $USER | grep "screen" | sed -e 's/?.*screen//' -e s'/ //')
                #KILL ONLY AFTED DEADBEEF RECEIVED!
                echo "Killing pid: $PID" >> $CONLOG
                sudo kill 9 $PID
                #RESET CRON
                echo "Stopping cron..." >> $CONLOG
                sudo service cron stop
                crontab $CRONFILE
                #START preceiver.sh AGAIN, WHEN FINISHED
                echo "Extracting data from pingdump..." >> $CONLOG
                bash $EXTRACTOR
                echo "Removing temp files" >> $CONLOG
                echo "Restarting listener..." >> $CONLOG
                bash $PRECEIVER
                echo "Restarting cron..." >> $CONLOG
                sudo service cron start
        else
                echo "CONTENT END NOT FOUND, NEW POLL IN 1MIN" >> $CONLOG
        fi
fi
