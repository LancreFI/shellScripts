!/bin/bash
encoding="${1}"
convertee="${2}"

if [ ! -z "${encoding}" ]
then
        if [ -z "${convertee}" ]
        then
                echo "You need to give the input to convert to Powershell Base64 (UTF16LE)"
        else
                if [[ "${encoding^^}" == "UNICODE" ]]
                then
                        echo "${convertee}" | iconv --to-code UTF-16LE | base64 -w 0
                elif [[ "${encoding}" == "UTF8" ]]
                then
                        echo -n "${convertee}" | iconv -f UTF8 -t UTF16LE | base64
                else
                        echo "Unknown encoding option ${encoding}!"
                fi
        fi
else
        echo "You need to specify the encoding <unicode|utf8>!"
fi
