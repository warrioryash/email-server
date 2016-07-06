#!/bin/bash

# ---------------CONFIGURATION---------------

# Set the IP/Domain name of email server in the cloud
DOMAINS[0]='YOURIPADDRESSHERE'
# This script assumes that you can loginto your remote
# server using Key-based authentication (public/private keys)
# If not, you will be prompted for a password

# ---------------END CONFIGURATION---------------

# Check for certificate files
{
if [ ! -f CA\ Certificate/CA-dovecot.pem ]; then
    echo "CA Certificate not found!"
    exit 0
fi
}

{
if [ ! -f FINAL\ CERTIFICATE/dovecot.pem ]; then
    echo "FINAL  Certificate not found!"
    exit 0
fi
}

{
if [ ! -f PRIVATE\ KEY/dovecot.pem ]; then
    echo "PRIVATE KEY not found!"
    exit 0
fi
}

{
if [ ! -f email-server.sh ]; then
    echo "email-server.sh not found!"
    exit 0
fi
}

# Use SFTP to move the certificates to server
sftp root@${DOMAINS[0]} <<\EOF  
put email-server.sh /root
put CA\ Certificate/CA-dovecot.pem /etc/ssl/certs/
put FINAL\ CERTIFICATE/dovecot.pem /etc/ssl/certs/
put PRIVATE\ KEY/dovecot.pem /etc/ssl/private/
  quit
EOF

# VERY IMPORTANT: Set permissions for the certificates
# Dovecot installation will fail without proper permissions
ssh root@${DOMAINS[0]} <<\EOF  
chmod ug+wrx ~/email-server.sh
chmod 400 /etc/ssl/private/dovecot.pem
chmod 444 /etc/ssl/certs/dovecot.pem
chmod 444 /etc/ssl/certs/CA-dovecot.pem 
cd /root



# INSTALL email server
./email-server.sh | tee INSTALL.log

reboot
EOF

# Create certificate for iPhone. Install this certificate 
# on the iphone by emailing yourself the certificate.
# Tap the attachment to intall the certificate. 
# openssl pkcs12 -export -in /etc/ssl/certs/dovecot.pem -inkey /etc/ssl/private/dovecot.pem -certfile /etc/ssl/certs/CA-dovecot.pem -out dovecot.p12
