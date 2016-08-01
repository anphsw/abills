#!/bin/sh



MIKROTIK=1;
MIKROTIK_HOSTS="194.44.41.82";

SUDO=/usr/local/bin/sudo
IPFW=/sbin/ipfw
SSH=/usr/bin/ssh
SSH_USER=abills_admin
VERSION=0.2
DEBUG="1"

#Check neg deposit speed
CHECK_NEG_DEPOSIT_SPEED=`grep abills_neg_deposit_speed /etc/rc.conf`


#************************************************
#
#************************************************
mikrotik_skip () {
	IP=${REMOTE_ADDR};

  for host in ${MIKROTIK_HOSTS}; do
    CMD=${CMD}" ${SSH} -o ConnectTimeout=10 -i /usr/abills/Certs/id_dsa.${SSH_USER} ${SSH_USER}@${host} \"/ip firewall address-list remove [find address=${IP}]\"; ";
  done;

}


#************************************************
#Freebsd version
#************************************************
freebsd_skip () {
	
	CMD="${SUDO} ${IPFW} table 32 delete ${REMOTE_ADDR}"

}


#**********************************************************
#
#**********************************************************
show_redirect_page () {
	
if [ x${HTTP_REFERER} != x ]; then
   if [ x${QUERY_STRING} != x ]; then
     REDIRECT_LINK=`echo "${QUERY_STRING}" | sed 's/redirect=//'`
     if [ x${REDIRECT_LINK} != x ]; then    
       echo "Location: http://${REDIRECT_LINK}";
       echo
     else
       echo "Content-Type: text/html";
       echo ""

       echo "Limited mode activated";
     fi
   else 
     echo "Content-Type: text/html";
     echo ""
   
     echo "Limited mode activated";
  fi;
else
  echo "Content-Type: text/html";
  echo ""
  echo "nothing to do"
fi;
	
}


if [ x"${MIKROTIK}" != x"" ]; then
  mikrotik_skip
else
  freebsd_skip
fi;


if [ x${DEBUG} != x ]; then
  echo "Content-Type: text/plain";
  echo ""
  echo ${CMD}
  echo
  env
fi;

${CMD}
if [ x${LOG} != x ]; then
  echo "${CMD}" >> /tmp/skip_warning
fi;

if [ x${CHECK_NEG_DEPOSIT_SPEED} = x ]; then
  echo "Content-Type: text/plain";
  echo ""
  echo "Neg deposit speed disable"
  exit;
fi;




