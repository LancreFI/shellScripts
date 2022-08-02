<pre>
gitGet.sh
'---> Carve/download files from public facing .git/ where directory listing is disabled
      Still unfinished. At the moment only downloads from the root dir of a host (target.host/.git/) also would require a lot more of error checking etc.
      Carving is based on the standard files refs/heads/master and logs/refs/heads/master, also polls for some other standard files first, then carves the object based on these two masters.
      Unfinished and tested only on one CTF, where we had the difficulty of having to do too much manual labour :D
      Might be useful together with nameinfo.sh and well-known.sh, maybe I'll bundle these up one day...

reconv.sh
'---> After converting VMGs to human readable files with vmgconv.sh, reconvert the message content from the messages to one single file MESCON.

vmgconv.sh
'---> Convert old Nokia .vmg SMS-messages to a more readable format.
      Usage: place in the same folder with the .vmg files and run "bash vmgconv.sh"
      It will remove the garbage and then output the content to originalfile_conv file.
      Only recodes both upper- and lowercase åäö at the moment out of the special characters.
      
checkQuota
'---> A cronable script to poll your Elisa consumer mailbox quota and raise alerts if needed.

utf2dec.sh
'---> Convert UTF8 characters to HTML decimal format
      Ran into problems ages ago when polling Clash Royale API for clan statistics with bash, as the names in the game can contain basically any characters, including emojis and had to print them into an HTML-page.
      This script converts characters to UTF8 codepoints and then to (HTML) decimal format.
      Usage example:
            [user@some]$ bash utf2dec.sh sometext
            &#38;#115;&#38;#111;&#38;#109;&#38;#101;&#38;#116;&#38;#101;&#38;#120;&#38;#116;
            
well-known.sh
'---> Check for /.well-known/ registered URI's (RFC8615)
      Another CTF-script for recon/web.
      Maybe useful to bundle with gitGet.sh and nameinfo.sh
      
nameinfo.sh
'---> Check every kind of DNS-record for a domain, check a couple of common TXT-records, robots file and whois
      Just another quick script to check info on a domain, sometimes useful for CTF's.
      Add more power by combining with gitGet.sh and well-known.sh
      
elastic_tool.sh
'---> Quick info / docs from ElasticSearch
      Just a quick bash-script to get info from ElasticSearch. No need for parameters, should ask for everything needed. Might need to change the /usr/bin/curl part to point to your curl -location.
      
pingExfil
'---> Exfiltrate data through PING packets
</pre>
