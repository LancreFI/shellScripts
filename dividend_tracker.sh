#!/bin/bash
variable_file="/home/user/stock_tracker/stock_list.yaml"
html_output="/home/user/tracker.html"
data_folder="/home/user/stock_tracker/"
pinger_temp_file="/home/user/stock_tracker/ping_data"

tickers=()
names=()
sources=()
uuids=()
slugs=()
ids=()
dividend_datafiles=()
instrument_datafiles=()

identity="/home/user/.ssh/tracker_user"
target="user@10.0.0.10:/home/user/stock_tracker/"

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
        echo "|                              DividendTracker v0.1                                 |"
        echo "|                                                                                   |"
        echo "${divider}"
}

help_message()
{
        echo "${divider}"
        echo
        echo "Usage: bash stock_tracker.sh <OPTIONS>"
        echo
        echo "  Where <OPTIONS>: -d / --default     == default settings, loads stock variables from ${variable_file}"
        echo "                   -f / --file <FILE> == loads stock variables from a custom <FILE>"
        echo "                   -n / --no-update   == don't update the stored data files (to avoid stressing the API)"
        echo "  NOTE: THE ORDER OF OPTIONS NEED TO BE THE SAME AS ABOVE!"
        echo
        echo "  Example: bash stock_tracker.sh -f /home/user/custom_list.yaml --no-update"
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
        
        #Currently only signal as pinger, mine is hosted elsewhere so need to upload a triggering file there
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
                        if grep -sq '"status":404' "${data_folder}${dividend_datafile}"
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

write_html()
{
        if [[ "${1,,}" == "tail" ]]
        then
                printf "\n\t\t<script>\n\t\tfunction plotAction(plot) {\n\t\t\tif ( plot.className === 'active' ){\n\t\t\t\tplot.firstChild.textContent='[hide\xa0plot]';" >> "${html_output}"
                printf "\n\t\t\t\tplot.nextElementSibling.className = 'plot_visible';\n\t\t\t\tplot.className = '';\n\t\t\t}\n\t\t\telse{\n\t\t\t\tplot.firstChild.textContent='[show\xa0plot]';" >> "${html_output}"
                printf "\n\t\t\t\tplot.nextElementSibling.className = 'plot_hidden';\n\t\t\t\t  plot.className = 'active';\n\t\t\t}\n\t\t}\n\t\t</script>\n\t</body>\n</html>" >> "${html_output}"
        elif [[ "${1,,}" == "head" ]]
        then
                printf "<html>\n\t<head>\n\t\t<title>StockTracker v0.2</title>\n\t\t<script src='plotly.js'></script>\n\t\t<style type='text/css'>\n\t\t" > "${html_output}"
                printf ".action\t{\n\t\t\tposition: relative;\n\t\t\twidth: 40px;\n\t\t\theight: 20px;\n\t\t\tcolor: green;\n\t\t}\n\n\t\t.button {\n\t\t\t" >> "${html_output}"
                printf "font-family: monospace;\n\t\t\tfont-size: 1em;\n\t\t\tcolor: #00ffff;\n\t\t}\n\n\t\t.plot_container {\n\t\t\tbackground-color: #333333;" >> "${html_output}"
                printf "\n\t\t\tdisplay: inline;\n\t\t\tdisplay: flex;\n\t\t\tflex-direction: row;\n\t\t}\n\n\t\t.plot_hidden{\n\t\t\tvisibility: hidden;\n\t\t" >> "${html_output}"
                printf "}\n\n\t\t.plot_visible{\n\t\t\tvisibility: visible;\n\t\t}\n\n\t\t.status_past, .dividend_past, .date_past {\n\t\t\tcolor: #ff0000;\n\t\t" >> "${html_output}"
                printf "}\n\n\t\t.status_today_x, .dividend_today_x, .date_today_x {\n\t\t\tcolor: #ff00ff;\n\t\t}\n\n\t\t" >> "${html_output}"
                printf ".status_today_pay, .dividend_today_pay, .date_today_pay {\n\t\t\tcolor: #cc00ff;\n\t\t}\n\n\t\t" >> "${html_output}"
                printf ".status_upcoming_pay, .dividend_upcoming_pay, .date_upcoming_pay {\n\t\t\tcolor: #ffff00;\n\t\t}\n\n\t\t" >> "${html_output}"
                printf ".status_upcoming_x, .dividend_upcoming_x, .date_upcoming_x {\n\t\t\tcolor: #00ff00;\n\t\t}\n\n\t\t" >> "${html_output}"
                printf ".ticker {\n\t\t\tfont-weight: bold;\n\t\t}\n\n\t\t" >> "${html_output}"
                printf ".ticker_container {\n\t\t\tbackground-color: #333333;\n\t\t\tcolor: #ffffff;\n\t\t\tfont-family: monospace;\n\t\t\t" >> "${html_output}"
                printf  "padding: 10px 0 0 10px;\n\t\t}\n\t\t</style>\n\t</head>\n\t<body>" >> "${html_output}"
        elif [[ "${1,,}" == "data_dividends" ]] || [[ "${1,,}" == "data_nodividends" ]]
        then
                symbol=$(sed 's/ /_/g' <<< "${2}")
                name="${3}"
                stock_value="${4}"
                currency="${5}"
                pe="${6}"
                ps="${7}"
                eps="${8}"
                pb="${9}"
                dps="${10}"
                dy="${11}"
                mapfile -d" " -t change <<< "${12}"
                change_perc="${change[1]}"
                change_value="${change[0]}"
                printf "\n\t\t<div class='ticker_container'>\n\t\t\t<div class='ticker' id='${symbol,,}'><b>${symbol^^}: ${name}</b></div>\n\t\t\t" >> "${html_output}"
                printf "<div class='value'>${stock_value} (${currency})</div>\n\t\t\t<div class='change'>Change: ${change_perc}&#37; (${change_value} ${currency})</div>\n\t\t\t" >> "${html_output}"
                printf "<div class='properties'>PE: ${pe}, PS: ${ps}, EPS: ${eps}, PB: ${pb}</div>\n\t\t\t" >> "${html_output}"

                if [[ "${1,,}" == "data_dividends" ]]
                then
                        printf "<div class='dividend'>Dividend per share: ${dps} (${currency}), dividend yield: ${dy}&#37;</div>\n\t\t\t" >> "${html_output}"
                        mapfile -d" " -t paydates <<< "${13}"
                        mapfile -d" " -t sums <<< "${14}"
                        mapfile -d" " -t exdates <<< "${15}"
                        mapfile -d" " -t dividend_status <<< "${16}"
                        mapfile -d" " -t dividend_type <<< "${17}"
                        class=""
                        counter=0

                        for status in "${dividend_status[@]}"
                        do
                                status=$(sed 's/_/ /g' <<< "${status}")
                                
                                if [[ "${status,,}" == "upcoming x date" ]]
                                then
                                        class="upcoming_x"
                                elif [[ "${status,,}" == "x date today" ]]
                                then
                                        class="today_x"
                                elif [[ "${status,,}" == "payment date today" ]]
                                then
                                        class="today_pay"
                                elif [[ "${status,,}" == "upcoming payment date" ]]
                                then
                                        class="upcoming_pay"
                                else
                                        class="past"
                                fi

                                if [[ "${status,,}" == "upcoming x date" ]] || [[ "${status,,}" == "x date today" ]] || [[ "${status,,}" == "upcoming payment date" ]] || [[ "${status,,}" == "payment date today" ]] || [[ "${counter}" -eq 0 ]]
                                then
                                        type=$(sed 's/_/ /g' <<< "${dividend_type[${counter}]}")
                                        printf "<div class='status_${class}'>Status: ${status,,}  Type: ${type}</div>\n\t\t\t" >> "${html_output}"
                                        printf "<div class='dividend_${class}'>${sums[${counter}]} (${currency})</div>\n\t\t\t" >> "${html_output}"
                                        printf "<div class='date_${class}'>Ex-date: ${exdates[${counter}]}  Payment: ${paydates[${counter}]}</div>\n\t\t\t" >> "${html_output}"
                                        ((counter++))
                                fi
                        done

                        if [[ "${#sums[@]}" -gt 0 ]]
                        then
                                x_axis=$(sed "s/ /','/g" <<< "${paydates[@]}")
                                y_axis=$(sed 's/ /,/g' <<< "${sums[@]}")

                                printf "<div id='${symbol,,}_master_container' class='plot_container'>\n\t\t\t\t" >> "${html_output}"
                                printf "<div id='${symbol,,}_action' onclick='plotAction(this)' class='active'><p class='button'>[show&nbsp;plot]</p></div>\n\t\t\t\t" >> "${html_output}"
                                printf "<div id='${symbol,,}_plotcontainer' class='plot_hidden'>\n\t\t\t\t\t<div id='${symbol,,}_plot'></div>\n\t\t\t\t\t" >> "${html_output}"

                                printf "<script>\n\t\t\t\t\t\tconst xArray_plot_${symbol,,} = ['${x_axis}'];\n\t\t\t\t\t\t" >> "${html_output}"
                                printf "const yArray_plot_${symbol,,} = [${y_axis}];\n\t\t\t\t\t\tconst data_plot_${symbol,,} = [{\n\t\t\t\t\t\t\t" >> "${html_output}"
                                printf "x: xArray_plot_${symbol,,},\n\t\t\t\t\t\t\ty: yArray_plot_${symbol,,},\n\t\t\t\t\t\t\ttype: 'scatter',\n\t\t\t\t\t\tmode:'lines'\n\t\t\t\t\t\t}];\n\t\t\t\t\t\t" >> "${html_output}"
                                printf "const layout_plot_${symbol,,} = {\n\t\t\t\t\t\t\txaxis: {title: {text: 'Dividend date'}, showticklabels: true},\n\t\t\t\t\t\t\t" >> "${html_output}"
                                printf "yaxis: {title: {text: 'Dividend amount in ${currency}'}, showticklabels: true},\n\t\t\t\t\t\t\ttitle: 'Dividend by year/month'\n\t\t\t\t\t\t};" >> "${html_output}"
                                printf "Plotly.newPlot('${symbol,,}_plot', data_plot_${symbol,,}, layout_plot_${symbol,,});\n\t\t\t\t\t</script>\n\t\t\t\t</div>\n\t\t\t</div>" >> "${html_output}"
                        fi
                else
                        printf "<div class='status_none'>Status: no announced or historical dividend data</div>\n\t\t\t" >> "${html_output}"
                fi
                
                printf "\n\t\t<br/></div>" >> "${html_output}"
        else
                echo " ! Wrong params for write_html function !"
        fi
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
write_html "head"

##PARSE DATA
echo "Parsing details from data"
echo "${divider}"

for file in "${instrument_datafiles[@]}"
do
        data_file="${data_folder}${file}"
        dividend_paydays=()
        dividend_sums=()
        dividend_exdates=()
        dividend_status=()
        dividend_types=()
        
        if ! grep -sq '"status":404' "${data_file}"
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
                
                if ! grep -sq '"status":404' "${instrument_dividend_data}"
                then
                        mapfile -t dividend_events < <(grep -Po "amount.*?status.*?20[\d]{2}\-\d{2}\-\d{2}" "${instrument_dividend_data}")
                else
                        unset dividend_events
                fi
                
                dividend_output_counter=0
                ##Check for the ping tag
                dividend_ping=$(grep -Po '^{"ping":"(yes|no)"' "${instrument_dividend_data}" | sed -e 's/^.*:"//' -e 's/"//')
                ##Remove the ping tag
                sed -i 's/^{"ping":"'${dividend_ping}'",/{/' "${instrument_dividend_data}"
                pinger_data=""
                
                for event in "${dividend_events[@]}"
                do
                        currency=$(grep -Po '"currency":"\w*?"' <<< "${event}" | sed -e 's/".*:"//' -e 's/"//')
                        value=$(grep -Po '"value":\d*?\.\d*?}' <<< "${event}" | sed -e 's/".*://' -e 's/}//')
                        dividend_type=$(grep -Po 'pe":\{"displayName":"\w*?"' <<< "${event}" | sed -e 's/^.*:"//' -e 's/"//')
                        payment_date=$(grep -Po "paymentDate.*?\d{4}\-\d{2}\-\d{2}" <<< "${event}" | sed 's/^.*:"//')
                        ex_date=$(grep -Po "xDate.*?\d{4}\-\d{2}\-\d{2}" <<< "${event}" | sed 's/^.*:"//')
                        status=$(grep -Po "status\":\"[\w_]*?\"" <<< "${event}" | sed -e 's/^.*:"//' -e 's/"//')
                        dividend_paydays+=("${payment_date}")
                        dividend_sums+=("${value}")
                        dividend_exdates+=("${ex_date}")
                        dividend_status+=("${status}")
                        dividend_types+=("${dividend_type}")

                        if [[ "${status,,}" == "upcoming x date" ]] || [[ "${status,,}" == "x date today" ]] || [[ "${status,,}" == "upcoming payment date" ]] || [[ "${dividend_output_counter}" -eq 0 ]]
                        then
                                ##There might be additional dividens announced same time and will show as two different events
                                if [[ "${dividend_ping}" == "yes" ]]
                                then
                                        if [[ "${status,,}" == "upcoming x date" ]] || [[ "${status,,}" == "x date today" ]] || [[ "${status,,}" == "upcoming payment date" ]] || [[ "${status,,}" == "payment date today" ]]
                                        then
                                                if [[ "${dividend_output_counter}" -eq 0 ]]
                                                then
                                                        pinger_data="${symbol}: ${name}\nCurrent price: ${current_value} (${currency})\n\n  Status: ${status,,}\n  Type: ${dividend_type}\n  Dividend: ${value} ($currency)\n  Ex-date: ${ex_date}\n  Payment: ${payment_date}\n"
                                                else
                                                        pinger_data+="\n\n  Status: ${status,,}\n  Type: ${dividend_type}\n  Dividend: ${value} ($currency)\n  Ex-date: ${ex_date}\n  Payment: ${payment_date}\n"
                                                fi
                                        fi
                                fi
                                
                                ((dividend_output_counter++))
                        fi
                done
                
                if [[ "${#dividend_sums[@]}" -gt 0 ]]
                then
                        write_html "data_dividends" "${symbol}" "${name}" "${current_value}" "${currency}" "${pe}" "${ps}" "${eps}" "${pb}" "${dps}" "${dy}" "${difference[*]}" "${dividend_paydays[*]}" "${dividend_sums[*]}" "${dividend_exdates[*]}" "${dividend_status[*]}" "${dividend_types[*]}"
                else
                        write_html "data_nodividends" "${symbol}" "${name}" "${current_value}" "${currency}" "${pe}" "${ps}" "${eps}" "${pb}" "0" "0" "${difference[*]}"
                fi
                
                if [[ "${dividend_ping}" == "yes" ]]
                then
                        ping_user "signal" "${instrument}" "${pinger_data}"
                        echo " --> user pinged about ${symbol} dividend update"
                fi
        fi
done

##WRITE HTML TAIL
write_html "tail"
echo "Parsing done"
echo "'--> Results written to ${new_html_output}"
echo "${divider}"
