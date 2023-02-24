#!/bin/bash
CHARARR=("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z")
#ORIGINAL CIPHERTEXT
ITER1="PEBVGMIKWVIKRQKWHVZCUQDVGVKTFIQKSMKEKXPWPETIPDEQWTKB"
#CIPHERTEXT AFTER SECOND ENCODING
ITER2="ILJNOEUIKIMDZCOLHYSJYHHVXZWTSGBSCQSXLRIPWMLWCHMIIBXF"
#CIPHERTEXT AFTER FIRST ENCODING IS REMOVED
ITER3="WLLMKAZEHUILMOVTTNXFMJXRZZUAYGQGYYAXFNAXWTSWAXMPFBBS"
LIST1=()
LIST2=()
LIST3=()
#SPLIT TO CHARACTER ARRAYS
mapfile -t SPLIT1 < <(echo "$ITER1" | grep -o .)
mapfile -t SPLIT2 < <(echo "$ITER2" | grep -o .)
mapfile -t SPLIT3 < <(echo "$ITER3" | grep -o .)

#GO CHAR BY CHAR THROUGH ITER1 (ORIGINAL CIPHERTEXT)
for char in "${SPLIT1[@]}"
do
	#COUNTER
	CNTR=0
	#CHECK THE CURRENT ITER1 CHAR PLACE FROM CHARARR
	for chr in "${CHARARR[@]}"
	do
		if [[ "${char}" == "${chr}" ]]
		then
			#IF MATCH ADD CELL NUM TO LIST1
			LIST1+=("${CNTR}")
		else
			#OTHERWISE COUNT FORWARD
			((CNTR++))
		fi
	done
done

#GO CHAR BY CHAR THROUGH ITER2 (SECOND TIME ENCODED CIPHER)
for char in "${SPLIT2[@]}"
do
	#COUNTER
	CNTR=0
	#CHECK THE CURRENT ITER2 CHAR PLACE FROM CHARARR
	for chr in "${CHARARR[@]}"
	do
		if [[ "${char}" == "${chr}" ]]
		then
			#IF MATCH ADD CELL NUM TO LIST2
			LIST2+=("${CNTR}")
		else
			#OTHERWISE COUNT FORWARD
			((CNTR++))
		fi
	done
done

#GO CHAR BY CHAR THROUGH ITER3 (FIRST DECRYPTION REMOVED)
for char in "${SPLIT3[@]}"
do
	#COUNTER
	CNTR=0
	#CHECK THE CURRENT ITER3 CHAR PLACE FROM CHARARR
	for chr in "${CHARARR[@]}"
	do
		if [[ "${char}" == "${chr}" ]]
		then
			#IF MATCH ADD CELL NUM TO LIST3
			LIST3+=("${CNTR}")
		else
			#OTHERWISE COUNT FORWARD
			((CNTR++))
		fi
	done
done


KEY1=()
CNTR=0

#COUNT THE KEY VALUES FOR THE SECOND CIPHER ENCODING KEY
for num in "${LIST1[@]}"
do
	#IF THE PLACE VALUE OF ORIGINAL CIPHER CHAR IS LESS THAN THE RESULTING CIPHERTEXT CHAR
	if [[ "${num}" -lt "${LIST2[$CNTR]}" ]]
	then
		#THEN THE KEY VALUE IS ORIGINAL CIPHER CHAR'S NUM - RESULTING CIPHER CHAR'S NUM
		KEY1+=($((${LIST2[$CNTR]}-${num})))
	else
		#IF THE CHAR PLACE VALUES ARE EQUAL, THEN THE KEY CHAR IS IN CHARARR[0]
		if [[ "${num}" -eq "${LIST2[$CNTR]}" ]]
		then
			KEY1+=("0")
		else
			#OTHERWISE THE KEY CHAR IS IN CHARARR_LENGTH - ORIGINAL CIPHER CHAR'S NUM + REUSLTING CIPHER CHAR'S NUM
			KEY1+=($((${#CHARARR[@]}-${num}+${LIST2[$CNTR]})))
		fi
	fi
	((CNTR++))
done

KEY2=()
CNTR=0

#COUNTING THE DECIPHER KEY USES THE SAME LOGIC AS PREVIOUS KEY
for num in "${LIST3[@]}"
do
	if [[ "${num}" -lt "${LIST2[$CNTR]}" ]]
	then
		KEY2+=($((${LIST2[$CNTR]}-${num})))
	else
		if [[ "${num}" -eq "${LIST2[$CNTR]}" ]]
		then
			KEY2+=("0")
		else
			KEY2+=($((${#CHARARR[@]}-${num}+${LIST2[$CNTR]})))
		fi
	fi
	((CNTR++))
done
echo "Encrypted message: "
echo "$ITER1"
echo "|"
echo "'--> Encrypted with key 1: "
printf "     "
for keys in "${KEY1[@]}"
do
	printf "${CHARARR[${keys}]}"
done
echo
echo "     |"
echo "     '--> Becomes: "
echo "          $ITER2"
echo "          |"
echo "          '--> Decrypted with key 2: "
printf "               "
for keys in "${KEY2[@]}"
do
	printf "${CHARARR[${keys}]}"
done
echo
echo "                |"
echo "                '--> Becomes: "
echo "                     $ITER3"
ORIG=()
CNTR=0
#DECRYPTING THE ORIGINAL CIPHER
for num in "${LIST3[@]}"
do
	#IF THE FIRS DECRYPTED CIPHER'S CHAR VALUE IS LESS THAN THE FIRST CIPHER KEY'S
	if [[ "${num}" -lt "${KEY1[$CNTR]}" ]]
	then
		#THEN THE ORIGINAL CHARACTER IS CHARACTER ARRAY LENGHT - (FIRST CIPHERY KEY CHAR'S VALUE - FIRST DECRYPTED CIPHER'S CHAR VALUE)
		ORIG+=($((${#CHARARR[@]}-(${KEY1[$CNTR]}-${num}))))
	else
		#IF EQUAL, THEN ORIGINAL CHARACTER IS THE FIRST ONE IN THE CHARACTER ARRAY
		if [[ "${num}" -eq "${KEY1[$CNTR]}" ]]
		then
			ORIG+=("0")
		else
			#ELSE IT IS COUNTED BY FIRST DECRYPTED CIPHER'S CHAR VALUE - FIRST CIPHER KEY'S CHAR VALUE
			ORIG+=($((${num}-${KEY1[$CNTR]})))
		fi
	fi
	((CNTR++))
done

echo "                     |"
echo "                     '--> Decrypted with key 1: "
printf "                          "
for keys in "${KEY1[@]}"
do
	printf "${CHARARR[${keys}]}"
done
echo
echo "                          |"
echo "                          '--> Becomes the original message: "
printf "                               "
for keys in "${ORIG[@]}"
do
	printf "${CHARARR[${keys}]}"
done
echo
