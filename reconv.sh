#!/bin/bash
echo "" > MESCON
mapfile -t FILES < <(ls|grep "_conv")

for CONVF in "${FILES[@]}"
do
        SROW=$(grep -n "BEGIN:VBODY" "$CONVF"|sed 's/:.*$//')
        EROW=$(grep -n "END:VBODY" "$CONVF"|sed 's/:.*$//')
        COUNTER=$SROW
        echo "$CONVF" >> MESCON
        while [ $COUNTER -lt $((EROW-1)) ]
        do
                ((COUNTER=COUNTER+1))
                sed "$COUNTER"'q;d' "$CONVF" >> MESCON
        done
        echo "" >> MESCON
        echo "" >> MESCON
done
