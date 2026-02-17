#!/bin/bash
variable_file="/home/dividend_tracker/stock_list.yaml"
html_output="/home/dividend_tracker/public_html/dividends.html"
data_folder="/home/dividend_tracker/data/"
pinger_temp_file="/home/dividend_tracker/data/ping_data"

tickers=()
names=()
sources=()
uuids=()
slugs=()
ids=()
dividend_datafiles=()
instrument_datafiles=()

identity="/home/dividend_tracker/.ssh/ssh_identity"
target="dividend@10.0.0.61:/home/dividend_tracker/"

divider="-------------------------------------------------------------------------------------"
action="${1}"

nordnet_instrument_actions="https://api.prod.nntech.io/company-data/v1/corporate-actions/instruments/"
nordnet_dividends="/dividends"
nordnet_instrument_figures="https://www.nordnet.fi/api/2/instrument_search/query/instrument?apply_filters=instrument_id%3D"
nordnet_instrument_variables="https://api.prod.nntech.io/instrument/v1/slug/"

create_banner()
{
        echo "${divider}"
        echo "|                                                                                   |"
        echo "|                              DividendTracker v0.1a                                |"
        echo "|                                                                                   |"
        echo "${divider}"
}

help_message()
{
        echo "${divider}"
        echo
        echo "Usage: bash dividend_tracker.sh <OPTIONS>"
        echo
        echo "  Where <OPTIONS>: -d / --default     == default settings, loads stock variables from ${variable_file}"
        echo "                   -f / --file <FILE> == loads stock variables from a custom <FILE>"
        echo "                   -n / --no-update   == don't update the stored data files (to avoid stressing the API)"
        echo "  NOTE: THE ORDER OF OPTIONS NEED TO BE THE SAME AS ABOVE!"
        echo
        echo "  Example: bash dividend_tracker.sh -f /home/dividend_tracker/custom_list.yaml --no-update"
        echo
        echo "${divider}"
}

read_variables()
{
        mapfile -t LIST < <(cat "${variable_file}")
        rowcounter=1
        for row in "${LIST[@]}"
        do
                #Skip comments and start/end
                if ! grep -qP "^(#|\-\-\-|\.\.\.)" <<< "${row}"
                then
                        if grep -qP "^\- " <<< "${row}"
                        then
                                ticker=$(sed -e 's/- //' -e 's/:$//' <<< "${row}")
                                tickers+=("${ticker}")
                        elif grep -qP "^    name: " <<< "${row}"
                        then
                                name=$(sed -e 's/^    name: //' <<< "${row}")
                                if grep -qP "^[ ]*$" <<< "${name}"
                                then
                                        name="NAME_NOT_SET"
                                fi
                                names+=("${name}")
                        elif grep -qP "^    source: " <<< "${row}"
                        then
                                source=$(sed -e 's/^    source: //' <<< "${row}")
                                if grep -qP "^[ ]*$" <<< "${source}"
                                then
                                        source="NO_SOURCE_SET"
                                fi
                                sources+=("${source}")
                        elif grep -qP "^    id: " <<< "${row}"
                        then
                                id=$(sed -e 's/^    id: //' <<< "${row}")
                                if grep -qP "^[ ]*$" <<< "${id}"
                                then
                                        id="NO_ID_SET"
                                else
                                        nordnet_vars=$(curl -s -X "GET" "${nordnet_instrument_variables}${id}" -H "x-locale: fi-FI")
                                        slug=$(grep -Po '"displaySlug":".*?,' <<< "${nordnet_vars}" | sed -e 's/^.*:"//' -e 's/",//')
                                        uuid=$(grep -Po '"instrumentId":".*?,' <<< "${nordnet_vars}" | sed -e 's/^.*:"//' -e 's/",//')
                                fi
                                slugs+=("${slug}")
                                uuids+=("${uuid}")
                                ids+=("${id}")
                        else
                                printf "\nMALFORMED STOCK VARIABLES FILE!\n  Error on row ${rowcounter}: $row\n\n"
                                printf "The correct format: \n- TICKER\n    name: COMPANY NAME\n    source: Nordnet\n    id: <NORDNET TICKER UUID>\n\n"
                                printf "Note that there should be exactly four spaces before name/source/id!\n\n"
                                echo "${divider}"
                                exit
                        fi
                fi
                ((rowcounter++))
        done
}

ping_user()
{
        media="${1}"
        instrument="${2}"
        data="${3}"
        echo "${data}" > "${pinger_temp_file}"
        #Currently I use only signal as pinger, mine is hosted elsewhere so need to upload a triggering file there
        if [[ "${media}" == "signal" ]]
        then
                scp -i "${identity}" -q "${pinger_temp_file}" "${target}${instrument}"
        fi
        rm -- "${pinger_temp_file}"
}


update_dividend_data()
{
        src="${1,,}"
        instrument="${2,,}"
        slug="${3,,}"
        ping="no"
        if [[ "${src}" == "nordnet" ]]
        then
                dividend_datafile="${slug}_dividend_data.json"
                if [[ "${4}" != "noupdate" ]]
                then
                        dividend_url="${nordnet_instrument_actions}${instrument}${nordnet_dividends}"
                        old_checksum=$(cut -d"," -f1-10 "${data_folder}${dividend_datafile}" | md5sum | cut -d" " -f1)
                        curl -s -X "GET" "${dividend_url}" -o "${data_folder}${dividend_datafile}"
                        new_checksum=$(cut -d"," -f1-10 "${data_folder}${dividend_datafile}" | md5sum | cut -d" " -f1)
                        ##If there is no dividend data, obviously not pinging the user
                        if grep '"status":404' "${data_folder}${dividend_datafile}"
                        then
                                ping="no"
                        ##Checksum comparison between the old and new dividend data files
                        elif [[ "${old_checksum}" != "${new_checksum}" ]]
                        then
                                ping="yes"
                        fi
                        ##Add a ping tag and remove it later, this triggers the pinging of the user
                        sed -i 's/^{/{"ping":"'"${ping}"'",/' "${data_folder}${dividend_datafile}"
                fi

                if [[ ! -r "${data_folder}${dividend_datafile}" ]]
                then
                        echo "${divider}"
                        echo "Missing the stored data file!"
                        echo "${dividend_datafile}"
                        echo
                        echo "Try updating the data files!"
                        echo "${divider}"
                        exit
                else
                        dividend_datafiles+=("${dividend_datafile}")
                fi
        else
                echo "${divider}"
                echo "ONLY NORDNET IS SUPPORTED AS A SOURCE CURRENTLY!"
                echo "${divider}"
                exit
        fi
}

update_instrument_data()
{
        src="${1,,}"
        instrument="${2,,}"
        slug="${3,,}"
        id="${4,,}"
        if [[ "${src}" == "nordnet" ]]
        then
                instrument_datafile="${slug}_data.json"
                if [[ "${id}" != "noupdate" ]]
                then
                        instrument_figures_url="${nordnet_instrument_figures}${id}"
                        client_header="Client-Id: NEXT"
                        curl -s -X "GET" "${instrument_figures_url}" -H "${client_header}" -o "${data_folder}${instrument_datafile}"
                fi

                if [[ ! -r "${data_folder}${instrument_datafile}" ]]
                then
                        echo "${divider}"
                        echo "Missing the stored data file!"
                        echo "${instrument_datafile}"
                        echo
                        echo "Try updating the data files!"
                        echo "${divider}"
                        exit
                else
                        instrument_datafiles+=("${instrument_datafile}")
                fi
        else
                echo "${divider}"
                echo "ONLY NORDNET IS SUPPORTED AS A SOURCE CURRENTLY!"
                echo "${divider}"
                exit
        fi
}

update_data()
{
        counter=0
        count="${#tickers[@]}"
        while [ "${counter}" -lt "${count}" ]
        do
                name="${names[${counter}]}"
                ticker="${tickers[${counter}]}"
                source="${sources[${counter}]}"
                uuid="${uuids[${counter}]}"
                id="${ids[${counter}]}"
                slug="${slugs[${counter}]}"
                echo "| ${name}"
                echo "|   Slug: ${slug}"
                echo "|   Ticker: ${ticker}"
                echo "|   Source: ${source}"
                echo "|   UUID: ${uuid}"
                echo "|   ID: ${id}"
                if [[ "${1,,}" == "noupdate" ]]
                then
                        echo "'--> Skipping the update of data files"
                        update_instrument_data "${source}" "${uuid}" "${slug}" "noupdate"
                        update_dividend_data "${source}" "${uuid}" "${slug}" "noupdate"
                        echo "${divider}"
                elif [[ "{source}" != "NO_SOURCE_SET" ]] && [[ "${uuid}" == "NO_UUID_SET" ]]
                then
                        echo "${divider}"
                        echo "Ticker ${ticker} has source, but is missing the ${source}-UUID"
                        echo "${divider}"
                        exit
                elif [[ "${uuid}" != "NO_UUID_SET" ]]
                then
                        if [[ "${source}" != "NO_SOURCE_SET" ]]
                        then
                                echo "'--> Updating instrument data"
                                update_instrument_data "${source}" "${uuid}" "${slug}" "${id}"
                                sleep 5
                                echo "'--> Updating dividend data"
                                update_dividend_data "${source}" "${uuid}" "${slug}"
                                sleep 5
                                echo "'-------- [ done ] -------->"
                                echo "${divider}"
                        else
                                echo "${divider}"
                                echo "Ticker ${ticker} is missing the source for data!"
                                echo "${divider}"
                                exit
                        fi
                fi
                ((counter++))
        done
}

create_banner

##READ PARAMETERS
if [[ "${action,,}" == "-d" ]] || [[ "${action,,}" == "--default" ]]
then
        echo "Using the default stock variables: ${variable_file}"
        echo "${divider}"
        read_variables
elif  [[ "${action,,}" == "-f" ]] || [[ "${action,,}" == "--file" ]]
then
        if [[ -r "${2}" ]]
        then
                echo "Loading variables from: ${2}"
                echo "${divider}"
                variable_file="${2}"
                read_variables
        else
                echo "File ${2} is not accessible!"
                echo "${divider}"
        fi
else
        help_message
        exit
fi

##UPDATE STOCK DATA
if [[ "${*,,}" == *"-n" ]] || [[ "${*,,}" == *"-n "* ]] || [[ "${*,,}" == *"--no-update" ]] || [[ "${*,,}" == *"--no-update "* ]]
then
        update_data "noupdate"
else
        update_data
fi

##WRITE HTML HEAD
printf "<html>\n\t<head>\n\t\t<title>StockTracker</title>\n\t</head>\n\t<body style='background-color:#696969'>\n\t\t<table border=1>\n\t\t" > "${html_output}"

##PARSE DATA
echo "Parsing details from data"
echo "${divider}"
for file in "${instrument_datafiles[@]}"
do
        data_file="${data_folder}${file}"
        if ! grep '"status":404' "${data_file}"
        then
                instrument=$(grep -Po '"display_slug":".*?"' "${data_file}" | sed -e 's/^.*:"//' -e 's/"//' | head -1)
                instrument_data="${data_folder}${instrument}_data.json"
                instrument_dividend_data="${data_folder}${instrument}_dividend_data.json"
                name=$(grep -Po '"long_name":".*?"' "${instrument_data}" | sed -e 's/^.*:"//' -e 's/"//')
                symbol=$(grep -Po '"symbol":".*?"' "${instrument_data}" | sed -e 's/^.*:"//' -e 's/"//')
                current_value=$(grep -Po "last.*?\.\d{2}" "${instrument_data}" | sed 's/^.*://')
                mapfile -t difference < <(grep -Po "diff.*?\.\d{2}" "${instrument_data}" | sed 's/^.*://')
                currency=$(grep -Po 'currency":"\w*?"' "${instrument_data}" | sed -e 's/^.*:"//' -e 's/"//')
                pe=$(grep -Po '"pe":[\d\.]*?,' "${instrument_data}" | sed -e 's/^.*://' -e 's/,//')
                ps=$(grep -Po '"ps":[\d\.]*?,' "${instrument_data}" | sed -e 's/^.*://' -e 's/,//')
                eps=$(grep -Po '"eps":[\d\.]*?,' "${instrument_data}" | sed -e 's/^.*://' -e 's/,//')
                pb=$(grep -Po '"pb":[\d\.]*?,' "${instrument_data}" | sed -e 's/^.*://' -e 's/,//')
                dps=$(grep -Po '"dividend_per_share":[\d\.]*?,' "${instrument_data}" | sed -e 's/^.*://' -e 's/,//')
                dy=$(grep -Po '"dividend_yield":[\d\.]*?}' "${instrument_data}" | sed -e 's/^.*://' -e 's/}//')
                printf "\n\t\t\t<tr>\n\t\t\t\t<td><b>${symbol}: ${name}</b></td>\n\t\t\t</tr>\n\t\t\t<tr>\n\t\t\t\t<td>${current_value} (${currency})</td>" >> "${html_output}"
                printf "\n\t\t\t</tr>\n\t\t\t<tr>\n\t\t\t\t<td>Change: ${difference[1]}&#37; (${difference[0]} ${currency})</td>\n\t\t\t\t" >> "${html_output}"
                printf "\n\t\t\t</tr>\n\t\t\t<tr>\n\t\t\t\t<td>PE: ${pe}, PS: ${ps}, EPS: ${eps}, PB: ${pb}</td>" >> "${html_output}"
                printf "\n\t\t\t</tr>\n\t\t\t<tr>\n\t\t\t\t<td>Dividend per share: ${dps} ($currency), dividend yield: ${dy}&#37;</td>" >> "${html_output}"
                mapfile -t dividend_events < <(grep -Po "amount.*?status.*?20[\d]{2}\-\d{2}\-\d{2}" "${instrument_dividend_data}")
                dividend_output_counter=0
                ##Check for the ping tag
                dividend_ping=$(grep -Po '^{"ping":"(yes|no)"' "${instrument_dividend_data}"| sed -e 's/^.*:"//' -e 's/"//')
                ##Remove the ping tag
                sed -i 's/^{"ping":"'${dividend_ping}'",/{/' "${instrument_dividend_data}"
                pinger_data=""
                for event in "${dividend_events[@]}"
                do
                        currency=$(grep -Po '"currency":"\w*?"' <<< "${event}" | sed -e 's/".*:"//' -e 's/"//')
                        value=$(grep -Po '"value":\d*?\.\d*?}' <<< "${event}" | sed -e 's/".*://' -e 's/}//')
                        dividend_type=$(grep -Po 'pe":\{"displayName":"\w*?"' <<< "${event}" | sed -e 's/^.*:"//' -e 's/"//' -e 's/_/ /')
                        payment_date=$(grep -Po "paymentDate.*?\d{4}\-\d{2}\-\d{2}" <<< "${event}" | sed 's/^.*:"//')
                        ex_date=$(grep -Po "xDate.*?\d{4}\-\d{2}\-\d{2}" <<< "${event}" | sed 's/^.*:"//')
                        status=$(grep -Po "status\":\"[\w_]*?\"" <<< "${event}" | sed -e 's/^.*:"//' -e 's/"//' -e 's/_/ /g');
                        if [[ "${status,,}" == "upcoming x date" ]]
                        then
                                text_color=" style='color:#00ff00; font-weight:bold'"
                        elif [[ "${status,,}" == "x date today" ]]
                        then
                                text_color=" style='color:#ff00ff; font-weight:bold'"
                        elif [[ "${status,,}" == "upcoming payment date" ]]
                        then
                                text_color=" style='color:#ffff00; font-weight:bold'"
                        else
                                text_color=" style='color:#ff0000'"
                        fi


                        if [[ "${status,,}" == "upcoming x date" ]] || [[ "${status,,}" == "x date today" ]] || [[ "${status,,}" == "upcoming payment date" ]] || [[ "${dividend_output_counter}" -eq 0 ]]
                        then
                                printf "\n\t\t\t</tr>\n\t\t\t<tr>\n\t\t\t\t<td ${text_color}>Status: ${status,,}  Type: ${dividend_type}</td>" >> "${html_output}"
                                printf "\n\t\t\t</tr>\n\t\t\t<tr>\n\t\t\t\t<td ${text_color}>${value} ($currency)</td>" >> "${html_output}"
                                printf "\n\t\t\t</tr>\n\t\t\t<tr>\n\t\t\t\t<td ${text_color}>Ex-date: ${ex_date}  Payment: ${payment_date}</td>" >> "${html_output}"
                                printf "\n\t\t\t</tr>" >> "${html_output}"
                                ##There might be additional dividens announced same time and will show as two different events
                                if [[ "${dividend_ping}" == "yes" ]]
                                then
                                        if [[ "${status,,}" == "upcoming x date" ]] || [[ "${status,,}" == "x date today" ]] || [[ "${status,,}" == "upcoming payment date" ]]
                                        then
                                                if [[ "${dividend_output_counter}" -eq 0 ]]
                                                then
                                                        pinger_data="${symbol}: ${name}\nCurrent price: ${current_value} (${currency})\n\n  Status: ${status,,}\n  Type: ${dividend_type}\n  Dividend: ${value} ($currency)\n  Ex-date: ${ex>
                                                else
                                                        pinger_data+="\n\n  Status: ${status,,}\n  Type: ${dividend_type}\n  Dividend: ${value} ($currency)\n  Ex-date: ${ex_date}\n  Payment: ${payment_date}\n"
                                                fi
                                        fi
                                fi
                                ((dividend_output_counter++))
                        fi
                done
                if [[ "${dividend_ping}" == "yes" ]]
                then
                        ping_user "signal" "${instrument}" "${pinger_data}"
                        echo " --> user pinged about ${symbol} dividend update"
                fi
        fi
done

##WRITE HTML TAIL
printf "\n\t\t</table>\n\t</body>\n</html>" >> "${html_output}"
echo "Parsing done"
echo "'--> Results written to ${html_output}"
echo "${divider}"
