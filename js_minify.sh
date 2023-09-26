#!/bin/bash
minified=""
mapfile -t script < <(cat "${1}")
for row in "${script[@]}"
do
        row=$(sed -e 's/ =/=/g' -e 's/= /=/g' -e 's/; /;/g' \
                  -e 's/& /&/g' -e 's/ &/&/g' -e 's/;}/}/g' \
                  -e 's/| /|/g' -e 's/ |/|/g' \
                  -e 's/ +/+/g' -e 's/+ /+/g' \
                  -e 's/ -/-/g' -e 's/- /-/g' \
                  -e 's/! /!/g' -e 's/ !/!/g' \
                  -e 's/ :/:/g' -e 's/: /:/g' \
                  -e 's/ }/}/g' -e 's/} /}/g' \
                  -e 's/) /)/g' -e 's/ )/)/g' \
                  -e 's/ (/(/g' -e 's/( /(/g' \
                  -e 's/ ,/,/g' -e 's/, /,/g' \
                  -e 's/< /</g' -e 's/ </</' \
                  -e 's/> />/g' -e 's/ >/>/g' <<< "${row}")
        minified+="${row}"
done

echo "${minified}"
