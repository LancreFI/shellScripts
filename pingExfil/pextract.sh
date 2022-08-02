#!/bin/bash
USER="ubuntu"
PINGDUMP="/home/$USER/pinger/pingdump"
DTEMP="/home/$USER/pinger/dumptemp"
TDUMP="/home/$USER/pinger/tempdump"
B64="/home/$USER/pinger/b64"
OUTFILE="/home/$USER/pinger/captures/originalfile"$(date +%d%m%Y"_"%H%M"_UTC0")
#DETERMINE THE ROW OF THE FIRST INTERESTING LINE IN PINGDUMP
HEAD=$(cat $PINGDUMP | grep -n 0x0050 --max-count=1 | sed -e 's/:.*//')
((HEAD++))

#DETERMINE THE LAST LINE
END=$(wc -l < $PINGDUMP)

#GET CONTENT BETWEEN FIRST AND LAST LINE OF INTEREST TO DUMPTEMP
cat $PINGDUMP | sed -n $((HEAD)),$((END))"p" > $DTEMP

#FIND THE FIRST LINE OF THE FIRST ENDING PACKET
DBEEF=$(cat $DTEMP | grep -n "dead beef" --max-count=1 | sed -e 's/:.*//')

#GET CONTENT BETWEEN FIRST LINE AND END PACKET TO TEMPDUMP
cat $DTEMP | sed -n 1,$((DBEEF))"p" | grep 0x00 | sed -e 's/0x0000.*//g' -e 's/0x0010.*//g' > $TDUMP
#-e 's/\t//g' | sed -r '/^\s*$/d' > tempdump
rm $DTEMP

#GET THE FIRST DATA ROWS OF EVERY PACKET (AS THE LAST TWO OCTETS ONLY CONTAIN DATA OF INTEREST)
FIRSTROWS=($(cat $TDUMP | grep "0x0020" | sed -e 's/0x0020:  //g' | awk -F " " '{print $7$8}'))
SECONDROWS=($(cat $TDUMP | grep "0x0030" | sed -e 's/0x0030:  //g' | awk -F " " '{print $1$2$3$4$5$6}'))
rm $TDUMP

#GET THE LENGTH OR THE ARRAY (==AMOUNT OF PACKETS RECEIVED)
PACKETS=${#FIRSTROWS[@]}
((PACKETS--))
COUNTER=0;

#GO THROUGH EVERY DATA OCTET IN PACKETS
while [ $COUNTER -le $PACKETS ]
do
        #THE LAST PACKET CONTAINS HEX "DEAD BEEF", REMOVE IT AND CONVERT DATA BIN,
        #INPUT IS BIN AND OUTPUT HEX AND THEN DO XXD REVERSE CONVERTION TO BASE64
        if [ $COUNTER -eq $PACKETS ]
        then
                BIN=$(echo 'obase=16;ibase=2;'${FIRSTROWS[$COUNTER]}${SECONDROWS[$COUNTER]} | sed -e 's/dead//g' -e 's/beef//g' | bc)
                #CHECK THE LENGTH OF THE BINARY CONVERSION, SOURCE IS BIN OUTPUT IS HEX
                #AS BC SKIPS LEADING ZEROS, UNEQUAL LENGTHS NEED TO HAVE THE ZERO ADDED BACK
                LEN=${#BIN}
                if (( LEN == 7 || LEN == 5 || LEN == 3 || LEN == 1 ))
                then
                        printf "0$BIN" | xxd -r -p >> $B64
                else
                        printf "$BIN" | xxd -r -p >> $B64
                fi

        else
                BIN=$(echo 'obase=16;ibase=2;'${FIRSTROWS[$COUNTER]}${SECONDROWS[$COUNTER]} | bc)
                LEN=${#BIN}
                if (( LEN == 7 || LEN == 5 || LEN == 3 || LEN == 1 ))
                then
                        printf "0$BIN" | xxd -r -p >> $B64
                else
                                BIN=$(echo 'obase=16;ibase=2;'${FIRSTROWS[$COUNTER]}${SECONDROWS[$COUNTER]} | bc)
                LEN=${#BIN}
                if (( LEN == 7 || LEN == 5 || LEN == 3 || LEN == 1 ))
                then
                        printf "0$BIN" | xxd -r -p >> $B64
                else
                        printf "$BIN" | xxd -r -p >> $B64
                fi
        fi
        ((COUNTER++))
done

#DECRYPT THE BASE64 TO OUTFILE
cat $B64 | base64 -d > $OUTFILE
rm $B64
