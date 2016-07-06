#!/bin/bash
#Assuming root is the username you use to log into your server
DOMAINS[0]='YOURDOMAINNAME';
rsync -av root@${DOMAINS[0]}:/var/mail/vhosts/ ${DOMAINS[0]}/ 
