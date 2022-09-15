#!/bin/bash
TOKEN="INSERT_YOUR_HIBP_TOKEN_HERE"
AGENT="INSERT_YOUR_USER-AGENT_HERE"
##LAZY CHECK FOR A VALID EMAIL ADDRESS
MAILADDR=$(grep -iPo "[\w\d\.\-\_\+]+@[\w\d\.\-\_]+" <<< "${1}")
##CHECKING IF THE ADDRESS REMAINS THE SAME AFTER THE ABOVE
if [[ $(wc -m <<< "${MAILADDR}") -eq $(wc -m <<< "${1}") ]]
then
        ##GET THE INFO FOR AND ADDRESS FROM HIBP
        PWNRES=$(curl -sX "GET" "https://haveibeenpwned.com/api/v3/breachedaccount/${MAILADDR}?truncateResponse=false" \
        -H "hibp-api-key: ${TOKEN}" -H "User-agent: ${UAGENT}")

        ##IF HITS WERE FOUND
        if [[ "${#PWNRES}" -gt "0" ]]
        then
                echo " ----------------------------- "
                mapfile -t BNAME < <(grep -o '"Name":"[^"]*' <<< "${PWNRES}" | grep -o '[^"]*$')
                mapfile -t BTITL < <(grep -o '"Title":"[^"]*' <<< "${PWNRES}" | grep -o '[^"]*$')
                mapfile -t BDOMA < <(grep -o '"Domain":"[^"]*' <<< "${PWNRES}" | sed 's/"Domain":"$/"Domain":"|/g' | grep -o '[^"]*$')
                mapfile -t BDATE < <(grep -o '"BreachDate":"[^"]*' <<< "${PWNRES}" | grep -o '[^"]*$')
                mapfile -t BADDE < <(grep -o '"AddedDate":"[^"]*' <<< "${PWNRES}" | grep -o '[^"]*$')
                mapfile -t BDATA < <(grep -oP '"DataClasses":\[[\w\d\", ]+]' <<< "${PWNRES}" | sed -e 's/^.*\[//' -e 's/]//' -e 's/"//g' -e 's/,/, /g')

                HITS="${#BNAME[@]}"
                COUNTER="0"
                echo "${MAILADDR} was found in the following breach(es):"
                while [ "${COUNTER}" -lt "${HITS}" ]
                do
                        echo " ${BNAME[${COUNTER}]} - ${BTITL[${COUNTER}]}"
                        echo " Breached domain:      ${BDOMA[${COUNTER}]}"|sed 's/|/-/'
                        echo " Breach occurred:      ${BDATE[${COUNTER}]}"
                        echo " Breach discovered:    ${BADDE[${COUNTER}]}"
                        echo " Breached information: ${BDATA[${COUNTER}]}"
                        if [ $((COUNTER+1)) -lt "${HITS}" ]
                        then
                                echo "++++"
                        fi
                        ((COUNTER++))
                done
                echo " ----------------------------- "
        else
                echo "${MAILADDR} was not found in any known breach!"
        fi
        ##THE HIBP API HAS A 1500MS LIMIT BETWEEN SEARCHES
        sleep 1.5
else
        echo "INVALID MAIL ADDRESS!"
fi
