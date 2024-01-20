These are used in a Debian bookworm vm-instance to run an Unturned server.

<b>ServerHelper.sh</b> is a modified version of the ServerHelper.sh to write the server status output to a logfile which can then be polled with status_poller.sh

<b>status_poller.sh</b> is for getting the server status, returns either ERR for an error or the server code for connecting to the server. In my setup this is polled by a Discord bot.

<b>unturned.service</b> the service file you can place under /etc/systemd/system/ to run the server as a service
