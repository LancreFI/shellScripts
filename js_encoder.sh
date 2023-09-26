!/bin/bash
input="${1}"
max_length="${#input}"
counter=0
mapfile -t chararr < <(fold -w1 <<< "${input}")
while [ "${counter}" -lt "${max_length}" ]
do
        printf %d "'${chararr[${counter}]}"
        if [ "${counter}" -ne $((max_length-1)) ]
        then
                printf ","
        fi
        ((counter++))
done
