#!/bin/bash
set -x

CAPDN=MYDOMAIN
CAPTLD=LOCAL
LODN=mydomain
LOTLD=local
DCADMIN=administrator
ALLOWED_GROUPS="sec-dev sec-prod"

# Leave Domain
realm leave

# Cleanup
systemctl stop sssd.service
find /var/lib/sss/db/ -name '*.ldb' -delete
echo > /etc/sssd/sssd.conf
systemctl stop realmd.service
# signal-event nethserver-dnsmasq-save

# Join Domain
realm join -v --user=$DCADMIN --computer-ou="OU=Linux Box,DC=$LODN,DC=$LOTLD" --computer-name="$(hostname)" $LODN.$LOTLD

# sed -i "s/^#.*default_realm.*/default_realm = $CAPDN.$CAPTLD/g" /etc/krb5.conf

sed -i "s/^fallback_homedir.*/fallback_homedir = \/home\/$CAPDN\/%u/g" /etc/sssd/sssd.conf
sed -i "s/^use_fully_qualified_names.*/use_fully_qualified_names = False/g" /etc/sssd/sssd.conf

# realm permit -g $ALLOWED_GROUPS
# systemctl restart sssd.service

authselect check
authselect current --raw
authselect select sssd with-mkhomedir --force
# systemctl enable --now oddjobd.service
systemctl restart oddjobd.service

# signal-event nethserver-sssd-save

systemctl start sssd.service