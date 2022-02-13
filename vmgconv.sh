#!/bin/bash
mapfile -t VMGS < <(ls|grep -o "^.*.vmg$")

for VMG in "${VMGS[@]}"
do
        sed -e 's/\x00//g' -e 's/\xE4/ä/g' -e 's/\xC4/Ä/g' -e 's/\xF6/ö/g' -e 's/\xD6/Ö/g' -e 's/\xE5/å/g' -e 's/\xC5/Å/g' < "$VMG" > "$VMG""_conv"
done
