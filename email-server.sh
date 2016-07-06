#!/bin/bash
# ---------------CONFIGURATION---------------

# Set the hostname of email server
HOSTNAMES[0]='mail.YOURDOMAIN.COM'

# Set the domain name of email server
DOMAINS[0]='YOURDOMAIN.COM'

# Set Dovecot email users 
# First install (apt-get install dovecot-core) on your local machine.
# Then generate encrpted passwords for your users using this command: 
# doveadm pw -s MD5-CRYPT
# Paste the encrypted passwords here:
USERS[0]='user1@mail.YOURDOMAIN.COM:YOURMD5ENCRYPTEDPASSWORD'
USERS[1]='user2@YOURDOMAIN.COM:YOURMD5ENCRYPTEDPASSWORD'

# Set location of SSL Certificate ESCAPING THE \s
SSL_CERT_LOC='\/etc\/ssl\/certs\/dovecot\.pem'
SSL_KEY_LOC='\/etc\/ssl\/private\/dovecot\.pem'
# Set location of CA Intermediate Certificate file (this comes from StartSSL.com)
SSL_CA_LOC='\/etc\/ssl\/certs\/CA-dovecot\.pem'
# Set location of CA SSL Certificate WITHOUT escaping the \s
SSL_CA_LOC2='/etc/ssl/certs/CA-dovecot.pem'

# ---------------END CONFIGURATION---------------

# Update System
sudo apt-get update
sudo apt-get upgrade -y

# Install Postfix
sudo debconf-set-selections <<< "postfix postfix/mailname string ${HOSTNAMES[0]}"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string ${HOSTNAMES[0]}"
sudo apt-get install -y postfix

# Set Email server hostname
sudo sed -i "s/myhostname =.*/myhostname = ${HOSTNAMES[0]}/" /etc/postfix/main.cf

# Set the domain name that should appear in the FROM section of the email
sudo sed -i "s/myorigin =.*/myorigin = ${DOMAINS[0]}/" /etc/postfix/main.cf

# Configure SASL - Set parameters to setup SASL based authentication for Postfix.
# Postfix internally is capable of talking to "Dovecot's SASL service" via a unix socket.
sudo echo "# Handing off local delivery to Dovecot's LMTP" >>  /etc/postfix/main.cf
sudo echo "virtual_transport = lmtp:unix:private/dovecot-lmtp" >>  /etc/postfix/main.cf
sudo echo "smtpd_sasl_path = private/auth" >>  /etc/postfix/main.cf
sudo echo "smtpd_sasl_auth_enable = yes" >>  /etc/postfix/main.cf
sudo echo "smtpd_sasl_type = dovecot" >>  /etc/postfix/main.cf
sudo echo "smtpd_sasl_security_options = noanonymous" >>  /etc/postfix/main.cf
sudo echo "smtpd_tls_auth_only = yes" >>  /etc/postfix/main.cf
sudo echo "smtpd_tls_loglevel = 1" >>  /etc/postfix/main.cf
sudo echo "smtpd_tls_received_header = yes" >>  /etc/postfix/main.cf
sudo echo "smtpd_use_tls = yes" >>  /etc/postfix/main.cf
sed -i "s/^smtpd_tls_cert_file.*/smtpd_tls_cert_file = $SSL_CERT_LOC/" /etc/postfix/main.cf
sed -i "s/^smtpd_tls_key_file.*/smtpd_tls_key_file = $SSL_KEY_LOC/" /etc/postfix/main.cf
sudo echo "smtpd_tls_CAfile = $SSL_CA_LOC2" >>  /etc/postfix/main.cf
sudo echo "smtp_tls_CAfile  = $SSL_CA_LOC2" >>  /etc/postfix/main.cf

# Add mailbox domains. Specify the domains for which Postfix shall "accept" incoming mails.
# So specify all your inhouse domains over here. 
# Put the domains in a file named virtual_mailbox_domains.
sudo echo "#Virtual domains, users, and aliases" >>  /etc/postfix/main.cf
sudo echo "virtual_mailbox_domains = /etc/postfix/virtual_mailbox_domains" >>  /etc/postfix/main.cf
sudo echo "# virtual_mailbox_maps = /etc/postfix/virtual_mailbox_maps" >>  /etc/postfix/main.cf
sudo touch /etc/postfix/virtual_mailbox_domains

for j in "${HOSTNAMES[@]}"
do
	sudo echo "$j OK" >>  /etc/postfix/virtual_mailbox_domains
done

for k in "${DOMAINS[@]}"
do
	sudo echo "$k OK" >>  /etc/postfix/virtual_mailbox_domains
done

sudo postmap /etc/postfix/virtual_mailbox_domains

# Enable SMTPS and MSA
sudo sed -i 's/#submission inet n       -       y       -       -       smtpd/submission inet n       -       y       -       -       smtpd/'  /etc/postfix/master.cf
sudo sed -i 's/#smtps     inet  n       -       y       -       -       smtpd/smtps     inet  n       -       y       -       -       smtpd/'  /etc/postfix/master.cf
sudo service postfix restart

# Install dovecot core package and packages for imap, pop and lmtp support
echo "dovecot-core dovecot-core/create-ssl-cert boolean true" | debconf-set-selections
echo "dovecot-core dovecot-core/ssl-cert-name string ${HOSTNAMES[0]}" | debconf-set-selections
sudo apt-get install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd

# Mails for someone@example.com would be stored in /var/mail/vhosts/example.com/someone/
sudo sed -i 's/^mail_location = .*/mail_location = maildir:\/var\/mail\/vhosts\/%d\/%n/' /etc/dovecot/conf.d/10-mail.conf
sudo mkdir /var/mail/vhosts/

for i in "${HOSTNAMES[@]}"
do
	sudo mkdir /var/mail/vhosts/$i
done

# Create a user with name and group of vmail and uid and gid of 5000. Although the uid can be any number, we are choosing 5000 to indicate # that it is not an ordinary user. The "-r" option further specifies that this user is a system level user and does not have any login.
sudo groupadd -g 5000 vmail
sudo useradd -r -g vmail -u 5000 vmail -d /var/mail/vhosts -c "virtual mail user"
sudo chown -R vmail:vmail /var/mail/vhosts/

# Enable Secure IMAP
sudo sed -i 's/#port = 993/port = 993/' /etc/dovecot/conf.d/10-master.conf
sudo sed -i 's/#ssl = yes/ssl = yes/' /etc/dovecot/conf.d/10-master.conf

#Enable Secure POP3
sudo sed -i 's/#port = 995/port = 995/' /etc/dovecot/conf.d/10-master.conf

# Configure lmtp socket -  this is where the unix socket would be created. 
sudo sed -i 's/unix_listener lmtp {/unix_listener \/var\/spool\/postfix\/private\/dovecot-lmtp { \n mode = 0600 \n user = postfix \n group = postfix \n/' /etc/dovecot/conf.d/10-master.conf

# Configure SASL authentication socket
sudo sed -i 's/service auth {/service auth { \n unix_listener \/var\/spool\/postfix\/private\/auth { \n mode = 0666 \n user=postfix \n group=postfix \n }/' /etc/dovecot/conf.d/10-master.conf

# Insure that TLS/SSL encryption is always used for authentication purpose.
sudo sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = yes/' /etc/dovecot/conf.d/10-auth.conf

# Specify the format in which the password will be provided to dovecot.
sudo sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf


# Disable default Dovecot authentication, using "system users" (linux users from /etc/passwd).
sudo sed -i 's/!include auth-system.conf.ext/#!include auth-system.conf.ext/' /etc/dovecot/conf.d/10-auth.conf

# Tell Dovecot to authenticate using a separate file containing usernames and passwords
sudo sed -i 's/#!include auth-passwdfile.conf.ext/!include auth-passwdfile.conf.ext/' /etc/dovecot/conf.d/10-auth.conf

# Tell Dovecot where to look for the username and passwords in order to authenticate:
# The username_format "%u" means that the entire email address will be used as the username.
# When logging in from an email client you would use the email address as the username for both smtp and imap/pop.
# The userdb section tells dovecot where to read/write the mails for a given user. 
# We are using a fixed directory structure /var/mail/vhosts/%d/%n
# So mails for the user someone@example.com would be read from the following directory -
# /var/mail/vhosts/example.com/someone/

sudo echo "passdb {
  driver = passwd-file
  args = scheme=PLAIN username_format=%u /etc/dovecot/dovecot-users
}

userdb {
  driver = static
#  args = username_format=%u /etc/dovecot/dovecot-users
args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n

  # Default fields that can be overridden by passwd-file
  #default_fields = quota_rule=*:storage=1G

  # Override fields from passwd-file
  #override_fields = home=/home/virtual/%u
}" > /etc/dovecot/conf.d/auth-passwdfile.conf.ext

# username and passwords are stored in a file named /etc/dovecot/dovecot-users
sudo touch /etc/dovecot/dovecot-users

# Add users
for i in "${USERS[@]}"
do
   echo $i >> /etc/dovecot/dovecot-users
done

# Enable SSL in dovecot
sudo sed -i 's/ssl = no/ssl = required/' /etc/dovecot/conf.d/10-ssl.conf

# Set SSL CERTIFICATE & Location -- it is assumed that you will put the certificates in this location later
sudo sed -i "s/#ssl_cert = <\/etc\/dovecot\/dovecot\.pem/ssl_cert = <$SSL_CERT_LOC/" /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i "s/#ssl_key = <\/etc\/dovecot\/private\/dovecot\.pem/ssl_key = <$SSL_KEY_LOC/" /etc/dovecot/conf.d/10-ssl.conf

# Set location of CA Intermediate Certificate file (this comes from StartSSL.com)
sudo sed -i "s/#ssl_ca =/ssl_ca = <$SSL_CA_LOC/" /etc/dovecot/conf.d/10-ssl.conf

# Add dovecot to the Mail group so that it can access the inboxes under /var/mail 
sudo sed -i "s/#mail_privileged_group =/mail_privileged_group = mail/" /etc/dovecot/conf.d/10-mail.conf

# FIX: warning: do not list domain example.com in BOTH mydestination and virtual_mailbox_domains 
sudo sed -i "s/^mydestination = .*/mydestination = localhost\.com, localhost/" /etc/postfix/main.cf

# VERY IMPORTANT: Set permissions for the certificates
# Dovecot installation will fail without proper permissions
chmod 400 /etc/ssl/private/dovecot.pem
chmod 444 /etc/ssl/certs/dovecot.pem
chmod 444 /etc/ssl/certs/CA-dovecot.pem 




