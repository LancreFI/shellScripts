#!/bin/bash

##THE SCRIPT ACTUALLY STARTS ON THE BOTTOM
##THIS IS THE FUNCTION USED IN CONVERSION

UTF8CP2DEC ()
{
	##HELPER VARIABLES
	COMPTE=0
	OUT=""
	N=0
	##SPLIT THE NAME BY CODEPOINT TO AN ARRAY
	IFS=' ' read -r -a UTFLIST <<< "$1"
	for ((i=0;i<${#UTFLIST[@]};i++))
	do
		##TRANSLATE THE CP TO DEC BY TRANSFORMING IT TO BASE16
		B=$(echo $((16#${UTFLIST[$i]})))
		if [[ "$COMPTE" -eq 0 ]]
		then
			if [[ 0 -le "$B" && "$B" -le 0x7F ]]
			then
				OUT=$OUT$B" "
			elif [[ 0xC0 -le "$B" && "$B" -le 0xDF ]]
			then
				COMPTE=1
				N=$(($B&0x1F))
			elif [[ 0xE0 -le "$B" && "$B" -le 0xEF ]]
			then
				COMPTE=2
				N=$(($B&0xF))
			elif [[ 0xF0 -le "$B" && "$B" -le 0xF7 ]]
			then
				COMPTE=3
				N=$(($B&0x7))
			else
				echo "ERR $B"
			fi
		elif [[ "$COMPTE" -eq 1 ]]
		then
			if [[ "$B" -lt 0x80 || "$B" -gt 0xBF ]]
			then
				echo "ERR $B"
			fi
			COMPTE=$((COMPTE-1))
			AA=$(( ((N<<6)) | ((B-0x80)) ))
			OUT=$OUT$AA" "
			N=0
		elif [[ "$COMPTE" -eq 2 ]]
		then
			if [[ "$B" -lt 0x80 || "$B" -gt 0xBF ]]
			then
				echo "ERR $B"
			fi
			N=$(( ((N<<6)) | ((B-0x80)) ))
			COMPTE=$((COMPTE-1))
		elif [[ "$COMPTE" -eq 3 ]]
		then
			if [[ "$B" -lt 0x80 || "$B" -gt 0xBF ]]
			then
				echo "ERR $B"
			fi
			N=$(( ((N<<6)) | ((B-0x80)) ))
			COMPTE=$((COMPTE-1))
		fi
	done

	CP=$(echo "$OUT" | sed -e 's/ $//')
	IFS=' ' read -r -a LIST <<< "$CP"
	OUT=""

	##ADD THE &# TAGS TO THE BEGINNING AND ; TO THE END OF EVERY CHARACTER
	##TO MAKE IT A DECIMAL PRESENTATION OF A CHARACTER IN HTML
	for i in "${LIST[@]}"
	do
		OUT=$OUT"&#"$i";"
	done
	##RETURN THE RESULT
	printf "$OUT\n"
}

##CONVERT THE NAME FROM UTF TO UTF CODEPOINTS
NAME=$(echo $1| xxd -g 1 | sed -e 's/^0.*: //' -e 's/  .*$//' -e 's/ 0a$//')
##THEN PASS THE NAME TO THE FUNCTION
UTF8CP2DEC "$NAME"
