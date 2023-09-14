#!/bin/bash
target="${1}"
if ! grep -q "/$" <<< "${target}"
then
	target="${target}/"
fi

if [[ -f "${2}" ]]
then
  if [[ "${3}" ]] && [[ "${3}" =~ [0-9]+([.][0-9]+)?$ ]]
  then
    echo "Call interval set to $3"
    interval="${3}"
  else
    echo "Call interval set to default 0"
    interval="${3}"
  fi
	mapfile -t wordlist < <(cat "${2}")
	for word in "${wordlist[@]}"
	do
		res=$(curl -Isq "${target}${word}" | grep -v ":" | grep -Po "\d{3}")
		echo "${target}${word}  --  ${res}"
		sleep "${interval}"
	done
else
	echo "Wordlist ${2} not found!"
fi
