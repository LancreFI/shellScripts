#!/bin/bash
RECORDS=("A" "AAAA" "AFSDB" "APL" "CAA" "CDNSKEY" "CDS" \
"CERT" "CNAME" "CSYNC" "DHCID" "DLV" "DNAME" "DNSKEY" "DS" \
"HIP" "IPSECKEY" "KEY" "KX" "LOC" "MX" "NAPTR" "NS" "NSEC" \
"NSEC3" "NSEC3PARAM" "OPENPGPKEY" "PTR" "RRSIG" "RP" "SIG" \
"SMIMEA" "SOA" "SRV" "SSHFP" "TA" "TKEY" "TLSA" "TSIG" \
"TXT" "URI" "ANY" "AXFR" "IXFR" "OPT" "MD" "MF" "MAILA" \
"MB" "MG" "MR" "MINFO" "MAILB" "WKS" "NB" "NBSTAT" "NULL" \
"A6" "NXT" "KEY" "SIG" "HINFO" "RP" "X25" "ISDN" "RT" \
"NSAP" "NSAP-PTR" "PX" "EID" "NIMLOC" "ATMA" "APL" "SINK" \
"GPOS" "UINFO" "UID" "GID" "UNSPEC" "SPF" "NINFO" "RKEY" \
"TALINK" "NID" "L32" "L64" "LP" "EUI48" "EUI64" "DOA")


echo ".-------------------------------------------."
echo "|          POLLING FOR DNS RECORDS          |"
echo "'-------------------------------------------'"
for record in "${RECORDS[@]}"
do
        echo ".-------------------------------------------."
        echo "|             $record RECORD "
        echo "|                                           |"
        if [ "$record" = "CNAME" ]
        then
                dig "www.$1" in cname|sed -e 's/^;.*$//g' > tempf
        elif [ "$record" = "TXT" ]
        then
                dig "$1" in txt|sed -e 's/^;.*$//g' > tempf
                dig "_dmarc.$1" in txt|sed -e 's/^;.*$//g' >> tempf
                dig "_dkim.$1" in txt|sed -e 's/^;.*$//g' >> tempf
                dig "s1._domainkey.$1" in txt|sed -e 's/^;.*$//g' >> tempf
                dig "s2._domainkey.$1" in txt|sed -e 's/^;.*$//g' >> tempf
                dig "_domainkey.$1" in txt|sed -e 's/^;.*$//g' >> tempf
                dig "pm._domainkey.$1" in txt|sed -e 's/^.*$//g' >> tempf
                dig "mail._domainkey.$1" in txt|sed -e 's/^.*$//g' >> tempf
                dig "mandrill._domainkey.$1" in txt|sed -e 's/^.*$//g' >> tempf
                dig "google._domainkey.$1" in txt|sed -e 's/^.*$//g' >> tempf
        else
                dig "$1" IN "$record"|sed 's/^;.*$//g' > tempf
        fi
        sed -i '/^$/d' tempf
        cat tempf
        rm tempf
done

echo "'-------------------------------------------'"

echo ".-------------------------------------------."
echo "|           TESTING FOR ROBOTS.TXT          |"
curl -sL "$1/robots.txt"
echo "'-------------------------------------------'"

WHOIS=$(which whois)

if [ "$WHOIS" ]
then
        echo ".-------------------------------------------."
        echo "|     GETTING WHOIS INFO FOR THE DOMAIN     |"
        echo "|                                           |"
        whois -H "$1"
        echo "|                                           |"
        echo "'-------------------------------------------'"
else
        echo "############################################################"
        echo "##   COULD NOT OBTAIN WHOIS INFO FOR DOMAIN REQUESTED!    ##"
        echo "## MISSING WHOIS! INSTALL WITH \"sudo apt install whois\" ##"
        echo "############################################################"
fi
