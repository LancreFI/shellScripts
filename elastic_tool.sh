#!/bin/bash

assignPort()
{
	####CHECK THE PORT VALIDITY
	PORT="65536"
	while [ "$PORT" -lt 0 -o "$PORT" -gt 65535 ]
	do
		printf "#  Target port: " && read PORT
	done
}

assignProto()
{
	LOOP="true"
	while [ "$LOOP" == "true" ]
	do

	printf "#  Protocol (http or https)?\n\
#   1) HTTP\n\
#   2) HTTPS\n\
#  Protocol: " && read PROTO

		case "$PROTO" in
			1) PROTO="http"; LOOP="false";;
			2) PROTO="https"; LOOP="false";;
			*) echo "# Invalid protocol option!";;
		esac
	done
	printf "######################################################################################\n"
}

getIndices()
{
	printf "\
######################################################################################\n\
### INDICES:                                                                       ###\n\
######################################################################################\n"
	/usr/bin/curl -s -X GET $PROTO"://"$TARGET":"$PORT"/_cat/indices?v" | awk 'NR>1' | sed -e 's/^/# /g'

	INDICES=($(/usr/bin/curl -s -X GET $PROTO"://"$TARGET":"$PORT"/_cat/indices?v" | awk 'NR>1' | awk '{print $3}'))
	INDICES_DOC_COUNT=($(/usr/bin/curl -s -X GET $PROTO"://"$TARGET":"$PORT"/_cat/indices?v" | awk 'NR>1' | awk '{print $7}'))

	CASES=${#INDICES[@]}
	COUNTER=0

	printf "######################################################################################\n"

	echo "#  Choose the indice from these: "
	while [ $COUNTER -lt $CASES ]
	do
		CELL=$COUNTER
		COUNTER=$((COUNTER+1))
		echo "#   "$COUNTER") "${INDICES[$CELL]}
	done

	INDICE="0"
	while [ $INDICE -lt 1 -o $INDICE -gt $CASES ]
	do
		printf "#  Indice number: " && read INDICE
	done

	printf "######################################################################################\n"

	while [ "$LOOP" == "true" ]
	do

		printf "\
#   1) Print indice full content\n\
#   2) Save the content to file\n\
#  Option: " && read OPTION

		case "$OPTION" in
			1) echo "#  "; /usr/bin/curl -s -X POST $PROTO"://"$TARGET":"$PORT"/"${INDICES[$((INDICE-1))]}"/_search?pretty=true&size="${INDICES_DOC_COUNT[$((INDICE-1))]}"&q=*:*"|sed -e 's/^/#/g'; LOOP="false";;
			2) /usr/bin/curl -s -X POST $PROTO"://"$TARGET":"$PORT"/"${INDICES[$((INDICE-1))]}"/_search?pretty=true&size="${INDICES_DOC_COUNT[$((INDICE-1))]}"&q=*:*" > ${INDICES[$((INDICE-1))]}"_full";echo "#  Saved to file ${INDICES[$((INDICE-1))]}_full"; LOOP="false";;
			*) echo "# Invalid selection";;
		esac
	done
}

getNodesOverview()
{
	printf "######################################################################################\n"

	while [ "$LOOP" == "true" ]
	do
		printf "\
#   1) Print nodes overview\n\
#   2) Save the content to file\n\
#  Option: " && read OPTION

		case "$OPTION" in
			1) echo "#  "; /usr/bin/curl -s -X GET $PROTO"://"$TARGET":"$PORT"/_cat/nodes?v"|sed -e 's/^/# /g' ; LOOP="false";;
			2) /usr/bin/curl -s -X GET $PROTO"://"$TARGET":"$PORT"/_cat/nodes?v" > "nodes_overview"; echo "#  Saved to file nodes_overview"; LOOP="false";;
			*) echo "# Invalid selection";;
		esac
	done
}

getInfo()
{
	printf "######################################################################################\n"
	while [ "$LOOP" == "true" ]
	do
		printf "\
#   1) Print ElasticSearch info\n\
#   2) Save the content to file\n\
#  Option: " && read OPTION
		case "$OPTION" in
			1) echo "#  "; /usr/bin/curl -s -X GET $PROTO"://"$TARGET":"$PORT"/"|sed -e 's/^/# /g'; LOOP="false";;
			2) /usr/bin/curl -s -X GET $PROTO"://"$TARGET":"$PORT"/" > "elastic_info"; echo "#  Saved to file elastic_info"; LOOP="false";;
			*) echo "# Invalid selection";;
		esac
	done
}

printf "\
######################################################################################\n\
##                         ElasticSearch lister/extractor                           ##\n\
##  Should help listing ElasticSearch content                                       ##\n\
##  Just give the server IP + port, protocol and start saving content locally       ##\n\
######################################################################################\n\
#  Target host: " && read TARGET

	assignPort
	assignProto

	while [ "$LOOP" != "true" ]
	do
printf "#  Choose one:\n\
#   1) LIST INDICES\n\
#   2) NODES OVERVIEW\n\
#   3) ELASTICSEARCH INFO\n\
#   4) CHANGE TARGET\n\
#   5) CHANGE PORT\n\
#   6) EXIT\n\
#  Option: " && read COMMAND

	case "$COMMAND" in
		1) LOOP="true"; getIndices;;
		2) LOOP="true"; getNodesOverview;;
		3) LOOP="true"; getInfo;;
		4) printf "######################################################################################\n #  Target host: " && read TARGET;;
		5) printf "######################################################################################\n"; assignPort;;
		6) LOOP="true";;
		*) echo "# Invalid option!";;
	esac

	printf "######################################################################################\n"

	done
