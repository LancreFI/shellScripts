#!/bin/bash
ACCDATA="/home/username/checkQuota/mailadds"
COOKIEFILE="/home/username/checkQuota/quoCookie"
TEMPFILE="/home/username/checkQuota/quoTemp"
LOGFILE="/home/username/checkQuota/quoLog"

##THRESHOLD OF WHEN TO NOTIFY ABOUT BOX GETTING FULL
THRESH=90

##SETTINGS FOR THE OUTGOING MAIL
SENDERNAME="POLLER"
SENDERADD="poller@pollerdomain.com"
RECIPIENT="someone@yourdomain.net"

ADDS=($(cat "$ACCDATA"|grep -o ^.*:|sed -e 's/://'))
PWS=($(cat "$ACCDATA"|grep -o :.*$|sed 's/://'))
COUNT=0
LEN=$((${#ADDS[@]}-1))
TIME=$(date +%d"."%m"."%Y" "%H"."%M)

echo "#########################################################" >> "$LOGFILE"
echo "##   $TIME" >> "$LOGFILE"
echo "#########################################################" >> "$LOGFILE"
for num in "${!ADDS[@]}"
do

USR="${ADDS[$num]}"
PASS="${PWS[$num]}"

curl -b "${COOKIEFILE}" -c "${COOKIEFILE}" -s 'https://webmail.elisa.fi/' -H 'User-Agent: QuotaKekker LancreFI' > "$TEMPFILE"
TOKEN=$(grep "\"_token" "$TEMPFILE"|sed -e 's/^.*value="//' -e 's/">//')

curl -b "${COOKIEFILE}" -c "${COOKIEFILE}" -s -iL 'https://webmail.elisa.fi/?_task=login' \
  -H 'Connection: keep-alive' \
  -H 'Cache-Control: max-age=0' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'Origin: https://webmail.elisa.fi' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'User-Agent: QuotaKekker LancreFI' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Sec-GPC: 1' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: navigate' \
  -H 'Sec-Fetch-User: ?1' \
  -H 'Sec-Fetch-Dest: document' \
  -H 'Referer: https://webmail.elisa.fi/' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  --data-urlencode "_user=""${USR}" \
  --data-urlencode "_pass=""${PASS}" \
  -d '_token='"${TOKEN}"'&_task=login&_action=login&_timezone=Europe%2FHelsinki&_url=' \
  --compressed > "$TEMPFILE"

curl -b "${COOKIEFILE}" -c "${COOKIEFILE}" -s 'https://elisa.fi/?wm=logout' \
  -H 'authority: elisa.fi' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'User-Agent: QuotaKekker LancreFI' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'sec-gpc: 1' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-dest: document' \
  -H 'accept-language: en-US,en;q=0.9' \
  --compressed > /dev/null

rm "$COOKIEFILE"
PERC=$(grep id=\'elisa_quota "$TEMPFILE"|grep -o 'width:.*%'|sed -e 's/width://' -e "s/'>.*$//")
MEGS=$(grep id=\'elisa_quota "$TEMPFILE"|grep -o 'quota_txt.*$'|grep -o [0-9].*$|sed 's/<.*$//')
PERCheck=$(echo "$PERC"|sed 's/%//')

echo "#########################################################" >> "$LOGFILE"
echo "#   QUOTA USAGE FOR $USR IS:" >> "$LOGFILE"
echo "#-->$MEGS" >> "$LOGFILE"
echo "#-->$PERC" >> "$LOGFILE"

if [ "$PERCheck" -ge 95 ]
then
        echo "#   USAGE IS OVER $THRESH%, NOTIFYING $RECIPIENT!" >> "$LOGFILE"
        mail -s "MAILBOX GETTING FULL FOR USER $USR!" -aFrom:"$SENDERNAME"\<"$SENDERADD"\> "$RECIPIENT" <<< "MAILBOX GETTING FULL FOR $USR, QUOTA USED $PERC = $MEGS"
fi

echo "#########################################################" >> "$LOGFILE"

rm "$TEMPFILE"

if [ "$COUNT" -eq "$LEN" ]
then
        echo "#   DONE" >> "$LOGFILE"
echo "*********************************************************" >> "$LOGFILE"
echo "***                                                   ***" >> "$LOGFILE"
echo "*********************************************************" >> "$LOGFILE"

else
        ((COUNT++))
        echo "***Checking the next mailbox in 2 seconds..." >> "$LOGFILE"
        sleep 2
fi

done
