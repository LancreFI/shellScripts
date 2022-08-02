<pre>
A shell script to automatically check your Elisa consumer mailbox quota through wm

Just add your addresses to mailadds file in the format of one per row:
email@some.com:password
emai2@some.other.net:password

Then set the settings to quoKek.sh:
##THRESHOLD OF WHEN TO NOTIFY ABOUT BOX GETTING FULL
THRESH=90

##SETTINGS FOR THE OUTGOING MAIL
SENDERNAME="POLLER"
SENDERADD="poller@pollerdomain.com"
RECIPIENT="someone@yourdomain.net"

Run or cron.
</pre>
