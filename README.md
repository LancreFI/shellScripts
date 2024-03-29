<pre>
bashcord.sh
'---> Using a discord bot over bash/curl.
      
checkQuota
'---> A cronable script to poll your Elisa consumer mailbox quota and raise alerts if needed.

curlbuster.sh
'---> Check for filepaths in a domain using a wordlist, where there's the paths you want to test for as one 
      path per line. Run with: 
      bash curlbuster.sh https://targetdoma.in /path/to/wordlist <optional delay between requests int/dec>
      Tip: If you get a lot of 429 responses, increase the delay.

discobot.sh
'---> A script you can use as a Discord bot that can receive triggers to start, stop, restart and check a 
      Proxmox vm status. Use in combination with proxmox_user.sh (details a few rows further). Doesn't 
      require any parameters, just run with "bash discobot.sh".

elastic_tool.sh
'---> Quick info / docs from ElasticSearch
      Just a quick bash-script to get info from ElasticSearch. No need for parameters, should ask for 
      everything needed. Might need to change the /usr/bin/curl part to point to your curl -location.

enumhelper.ps1
'---> A helper script for AD enumeration and lateral movement. Built on-the-go so might contain a lot of
      logical fallacies and missing lots of error checks.
      Check the help section before running: .\enumhelper.ps1 "help" for somewhat of instructions.
      Can do: 
            - LDAP queries
            - User/pass testing over LDAP-query
            - List all properties of LDAP response object
            - Get the value of a specific LDAP property
            - Get all SPNs and related objects
            - Check if any SPNs are tied to a (service)account
            - Get DC info: name, hostname, OS, OS version, IPv4 and IPv6
            - Get AD device info: name, hostname, OS, OS SP, OS version, IPv4 and IPv6
            - Get AD user/group info by SID (converting a SID to a name for example)
            - Create PsExec.exe or PsExec64.exe
            - SID lookup from AD
            - DCOM lateral movement leveraging MMC
                  - Also the possibility of building a reverse-shell command and initiating it 
                    on the target
            - Remote connectiong over PowerShell
            - Remote commands over WMI, WINRS, PsExec or PsExec64:
                  - Also the possibility of building a reverse-shell command and initiating it 
                    on the target
            
gitGet.sh
'---> Carve/download files from public facing .git/ where directory listing is disabled
      Still unfinished. At the moment only downloads from the root dir of a host (target.host/.git/) also 
      would require a lot more of error checking etc.
      Carving is based on the standard files refs/heads/master and logs/refs/heads/master, also polls for 
      some other standard files first, then carves the object based on these two masters.
      Unfinished and tested only on one CTF, where we had the difficulty of having to do too much manual 
      labour :D
      Might be useful together with nameinfo.sh and well-known.sh, maybe I'll bundle these up one day...

ilo_control.sh
'---> Manage your Proliant running iLO4 over the API.
      Simple usage: bash ilo_control.sh <status|start|stop|restart>
      The restart isn't a ForceRestart but rather powercycle from start to stop to start again.
      You should create a separate account on your iLO4 for just this user and only assign the minimum
      permissions needed for whatever operations you want to run over iLO. Also there isn't an API-
      key anywhere but it's just basic auth with the username and password, so create a strong pw.
            
image_renamer.ps1
'---> PowerShell script to rename multiple files within a dir to have their timestamp as the name
      Run (with ISE or your choise of tool):    .\image_renamer.ps1
      Asks for the directory in which the files are located. Make sure the dir contains only files, no 
      subdirs or anything, as the behaviour's not tested on subdirs. Don't put the script inside the same 
      dir either.
      You can choose to use the last modification date or the Date taken -value from metadata (image files) 
      as the new filename (ddMMyy_HHmmss.extension).

js_decoder.sh
'---> Decode input, in my use case charcoded JavaScript. The same thing you'd do with JS by:
      String.fromCharCode(116,114,121,104,52,114,100,101,114)
      Usage: bash js_decoder.sh "116,114,121,104,52,114,100,101,114"
            
js_encoder.sh
'---> Encode input, in my use case JavaScript to charcodes, the same you usually do in JS by:
      variable="string";for(i=0;i&lt;variable.length;i++){console.log(variable.charCodeAt(i))}
      Usage: bash js_encoder.sh "some random string or javascript"

js_minify.sh
'---> A really crude level JavaScript minifier, which has barely been tested. Something I needed at one
      point and quickly whipped up.
      Usage: bash js_minify.sh javascript_file.js
      Note: Only tested with scirpts where every operation is one operation per row and ending with ;
            
nameinfo.sh
'---> Check every kind of DNS-record for a domain, check a couple of common TXT-records, robots file and 
      whois.
      Just another quick script to check info on a domain, sometimes useful for CTF's.
      Add more power by combining with gitGet.sh and well-known.sh

pingExfil
'---> Exfiltrate data through PING packets
      
proxmox_user.sh
'---> A quick script to control a vm in a Proxmox instance over the Proxmox API
      Just create an API token in Proxmox with the root account, assign it to a the vm you want to 
      control and give it the PVEVMUser rights.
      Usage: bash proxmox_user.sh <task>
      The task can be: status, stop, start or restart
      
pwncheck.sh
'---> Check leak info for email addresses from HaveIBeenPwned. You need a paid API-key to be able to 
      carve data and you also need to set your own user-agent, which can be anything of your choosing.
      The script is run by: bash pwncheck.sh email@tobe.check.ed
      The script only takes one address at a time and sleeps 1.5 seconds between API requests, as it is 
      the current limit on the API's side.
      You could have multiple addresses in a file, each on it's own row and run multiple searches like:  
      for user in $(cat addresses); do bash pwncheck.sh "${user}"; done

reconv.sh
'---> After converting VMGs to human readable files with vmgconv.sh, reconvert the message content from the 
      messages to one single file MESCON.

threePassMethod.sh
'---> Used at Disobey 2023 CTF, where we kned the ciphertext after first encoding, the result after second 
      encooding and the result after the first encoding was removed. This would figure out the used 
      Vigenere cipher keys and decipher the original ciphertext back to text.

to_psb64.sh
'---> As PowerShell uses UTF16LE the "normal" base64 default format from Linux won't do. You can do it with
      this script instead: bash to_psb64.sh unicode "text_to_base64_encode"
      If you for example want to encode some nasty payload etc. use the unicode option, in some cases the
      source might be UTF8, then use utf8 instead of unicode as the first parameter.
            
url_coder.py
'--> Use to percent encode/decode strings/urls: python3 url_coder.py <encode|decode> "string"

utf2dec.sh
'---> Convert UTF8 characters to HTML decimal format
      Ran into problems ages ago when polling Clash Royale API for clan statistics with bash, as the names 
      in the game can contain basically any characters, including emojis and had to print them into an 
      HTML-page.
      This script converts characters to UTF8 codepoints and then to (HTML) decimal format.
      Usage example:
            [user@some]$ bash utf2dec.sh sometext
            &#38;#115;&#38;#111;&#38;#109;&#38;#101;&#38;#116;&#38;#101;&#38;#120;&#38;#116;

vmgconv.sh
'---> Convert old Nokia .vmg SMS-messages to a more readable format.
      Usage: place in the same folder with the .vmg files and run "bash vmgconv.sh"
      It will remove the garbage and then output the content to originalfile_conv file.
      Only recodes both upper- and lowercase åäö at the moment out of the special characters.
            
well-known.sh
'---> Check for /.well-known/ registered URI's (RFC8615)
      Another CTF-script for recon/web.
      Maybe useful to bundle with gitGet.sh and nameinfo.sh

winbin.sh
'---> Whip up custom executable/dll on the fly. So far only supports creating an x64 executable/dll for 
      adding a defined user with a defined password to the Administrators group or changing an existing 
      user's password.
      For example if you need to replace a bin which you have full control over to gain further foothold 
      or to leverage a missing DLL etc.
</pre>
