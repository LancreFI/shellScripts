status_poller.sh is for getting the server status, returns either ERR for an error or the server code for connecting to the server. In my setup this is polled by a Discord bot.

ServerHelper.sh is a modified version of the ServerHelper.sh to write the server status output to a logfile which can then be polled with status_poller.sh
