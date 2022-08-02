#!/bin/bash
#Screen name running in the background was "preceiver", executing username was "ubuntu" and the receiving interface was "ens5"
screen -dmS preceiver
screen -S preceiver -X stuff "sudo tcpdump -i ens5 -e icmp[icmptype] == 8 -U -x -l > /home/ubuntu/pinger/pingdump `echo -ne '\015'`"
