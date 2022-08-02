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
</pre>
