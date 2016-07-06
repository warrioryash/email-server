#!/bin/bash

DOMAINS[0]='mail.YOURDOMAINNAME.COM'
IP='YOURIPADDRESS';

# Transfer INBOXES from local folder to the email server
rsync -av ${DOMAINS[0]}/ root@$IP:/var/mail/vhosts/

# VERY IMPORTANT: Set permissions for the mail folders!!!
chown -R vmail:vmail /var/mail/vhosts/
