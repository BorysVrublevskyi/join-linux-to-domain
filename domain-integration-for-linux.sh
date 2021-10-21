#!/bin/bash
set -x

CAPDN=MYDOMAIN
CAPTLD=LOCAL
LODN=mydomain
LOTLD=local
DCADMIN=administrator
ALLOWED_GROUPS="sec-dev sec-prod"

dnf install -y krb5-workstation realmd sssd authconfig oddjob oddjob-mkhomedir adcli sssd-tools # samba-common-tools
# apt install krb5-user realmd sssd oddjob oddjob-mkhomedir ldap-auth-config packagekit #leave default settings but for all questions say NO

cp -n /etc/krb5.conf{,.bak}

# nano /etc/krb5.conf
# default_realm = MYDOMAIN.LOCAL
sed -i "s/^#.*default_realm.*/default_realm = $CAPDN.$CAPTLD/g" /etc/krb5.conf

# ### Ubuntu only: nano /etc/nsswitch.conf # EDIT:
# hosts:          files dns mdns4_minimal [NOTFOUND=return]
# passwd:         compat systemd sss
# group:          compat systemd sss
# shadow:         compat sss

realm join -v -U $DCADMIN --computer-ou="OU=Linux Box,DC=$LODN,DC=$LOTLD" --computer-name="$(hostname)" $LODN.$LOTLD
# kinit administrator
# klist

mkdir /home/$CAPDN && chmod 751 /home/$CAPDN

cp -n /etc/sssd/sssd.conf /etc/sssd/sssd.conf.bak
# nano /etc/sssd/sssd.conf
# ###for section [domain/mydomain.local] change:
# fallback_homedir = /home/MYDOMAIN/%u
# use_fully_qualified_names = False
sed -i "s/^fallback_homedir.*/fallback_homedir = \/home\/$CAPDN\/%u/g" /etc/sssd/sssd.conf
sed -i "s/^use_fully_qualified_names.*/use_fully_qualified_names = False/g" /etc/sssd/sssd.conf

# Treat the specified names as groups rather than user login names. Permit login by users in the specified groups:
realm permit -g $ALLOWED_GROUPS

# authconfig --update --enablesssd --enablesssdauth --enablemkhomedir --nostart # For Ubuntu edit file /etc/nsswitch.conf (see above)
authselect check
authselect current --raw
authselect select sssd with-mkhomedir --force
systemctl enable sssd.service
systemctl enable --now oddjobd.service

systemctl restart sssd.service
