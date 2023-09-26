#!/bin/bash
input="${1}"
for code in $(grep -oP "\d+" <<< "${input}")
do
        printf $(printf '\%o' "${code}")
done
