#!/bin/bash
cd /home/unturned/server/unturned/
logfile="/home/username/unturned/unturned_serverlog.log"
# To mark this script as executable you may need to run "chmod +x ServerHelper.sh"

# Tell system where to find 64-bit steamclient.so. Without this command Steam API Init will fail with an unable to find file error.
# Thanks @Johnanater in issue #3243. There is a long history of steamclient.so issues (e.g. #2616) because sometimes the official
# dedicated server redist copy gets out of date if Valve forgets to update it, so in the past we have sometimes used the steamcmd
# version of steamclient.so if available.
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`dirname $0`/linux64

# Terminal mode compatible with -logfile 2>&1 IO.
export TERM=xterm

# Run the server binary.
# -batchmode and -nographics are Unity player arguments.
# -logfile 2>&1 can be used to pipe IO to/from the terminal.
# "$@" appends any command-line arguments passed to this script.
rm "${logfile}" 2>&1>/dev/null
touch "${logfile}"
chown username:username "${logfile}"
./Unturned_Headless.x86_64 -batchmode -nographics "$@" 2>&1 >> "${logfile}"
