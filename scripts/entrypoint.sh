#!/bin/sh

printf "\n### MIT KRB5 sidecar ###\n\n"

printf "This container includes everything necessary to authenticate with an Active Directory KDC or Kerberos KDC using a keytab. At a\ngiven interval kinit is executed to get a fresh ticket from the TGS. \n\n"

# Secure keytab
chmod 400 /krb5/common/krb5.keytab

# Copy KRB5 assets to standard KRB5 configuration paths
cp /krb5/sidecar/krb5.conf /etc/krb5.conf
cp -r /krb5/common/krb5.conf.d /etc/krb5.conf.d

# Copy KRB5 assets to shared memory location so these assets can be utilized by the sidecar client container
cp /krb5/common/krb5.keytab /dev/shm/krb5.keytab
cp /krb5/client/krb5.conf /dev/shm/krb5-client.conf
cp -r /krb5/common/krb5.conf.d /dev/shm/krb5.conf.d

[[ "$KINIT_WAIT_INTERVAL_IN_SECONDS" == "" ]] && KINIT_WAIT_INTERVAL_IN_SECONDS=3600

if [[ "$KINIT_OPTIONS" == "" ]]; then

  #[[ -e /krb5/common/krb5.keytab ]] && KINIT_OPTIONS="-k" && echo "*** using host keytab"
  [[ -e $KRB5_KTNAME ]] && KINIT_OPTIONS="-k" && echo "*** using host keytab"
  #[[ -e /krb5/common/client.keytab ]] && KINIT_OPTIONS="-k -i" && echo "*** using client keytab"
  [[ -e $KRB5_CLIENT_KTNAME ]] && KINIT_OPTIONS="-k -i" && echo "*** using client keytab"

fi

if [[ -z "$(ls -A /krb5)" ]]; then
  echo "*** Warning default keytab ($KRB5_KTNAME) or default client keytab ($KRB5_CLIENT_KTNAME) not found"
fi

while true
do
  echo "*** kinit at "+$(date -I)
   kinit -V $KINIT_OPTIONS $KINIT_APPEND_OPTIONS

   # List tickets held in the given credentials cache. 
   # klist -c /dev/shm/ccache
   klist -c $KRB5CCNAME
   echo "*** Waiting for $KINIT_WAIT_INTERVAL_IN_SECONDS seconds"
   sleep $KINIT_WAIT_INTERVAL_IN_SECONDS

done