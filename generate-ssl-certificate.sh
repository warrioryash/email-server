#!/bin/bash


# STEP 1: Enter your organization's info:
SUBJ="/C=US/ST=Georgia/L=Atlanta/O=yourdomain.com/organizationalUnitName=yourdomain.com/CN=yourdomain.com/emailAddress=USERNAME@yourdomain.com"

# Generate the Certificate Signing Request (www_csr.pem) and Private Key (www_privatekey.pem)
sudo openssl req -new -newkey rsa:4096 -nodes -keyout www_privatekey.pem -out www_csr.pem  -subj "$SUBJ"

# STEP 2: MANUAL STEP: Use www_csr.pem at https://www.startssl.com/ (register with them) to generate THE FINAL CERTIFICATE. Save it as www_certificate.pem

# Get Intermediate Certificate from the company - this is a middle certificate which is used to verify THE FINAL CERTIFICATE
sudo wget http://www.startssl.com/certs/sub.class1.server.ca.pem -O sub.class1.server.ca.pem

# Verify THE FINAL CERTIFICATE:
sudo cat sub.class1.server.ca.pem www_certificate.pem | openssl verify

# STEP 3: Move THE FINAL CERTIFICATE to the FINAL CERTIFICATE folder:
sudo cat sub.class1.server.ca.pem www_certificate.pem > FINAL\ CERTIFICATE/dovecot.pem

# Now generate a FINAL NEW PRIVATE KEY
sudo openssl req -new -x509 -days 3650 -nodes -out FINAL\ CERTIFICATE/dovecot.pem -keyout PRIVATE\ KEY/dovecot.pem -subj "$SUBJ"

# Set Permissions
sudo chmod 444 /etc/ssl/certs/dovecot.pem
sudo chmod 644 /etc/ssl/private/dovecot.pem











