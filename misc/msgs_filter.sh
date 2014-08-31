#!/bin/sh
# Message filter managment script
# Add, del filters

version=0.4
DEBUG=0;
IP=$1;

BILLING_DIR="/usr/abills/";

DB_USER=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbuser}' |awk -F"'" '{print $2}'`
DB_PASSWD=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbpasswd}' |awk -F"'" '{print $2}'`
DB_NAME=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbname}' |awk -F"'" '{print $2}'`
DB_HOST=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbhost}' |awk -F"'" '{print $2}'`
DB_CHARSET=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbcharset}' |awk -F"'" '{print $2}'`

MYSQL=`which mysql`


if [ x"${MYSQL}" = x ]; then
  MYSQL=/usr/local/bin/mysql
fi;

MSGS_TABLE_NUM=100

if [ w$1 = w ]; then
  echo "Add arguments";
  exit
fi;

ACTION=$1
UID=$2

#OS
OS=`uname`;

if [ x"${OS}" = x"FreeBSD" ]; then

  #Add online filter
  if [ w"${ACTION}" = wadd ]; then
    SQL="select INET_NTOA(framed_ip_address) AS ip from dv_calls WHERE uid IN (${UID});";
    OUTPUT=`${MYSQL} -h ${DB_HOST} -D ${DB_NAME} -p"${DB_PASSWD}" -u ${DB_USER} -e "${SQL}"`;

    for LINE in ${OUTPUT}; do
  
      IP=`echo ${LINE} | awk '{ print $1 }'`;
   #   UID=`echo ${LINE} | awk '{ print $2 }'`;
   
      if [ "${IP}" != 'ip' ]; then
        if [ w${DEBUG} != w ]; then
          echo "/sbin/ipfw table ${MSGS_TABLE_NUM} add ${IP} ${UID}";
        fi;

        /sbin/ipfw table ${MSGS_TABLE_NUM} add ${IP} ${UID}
      fi;
    
    done;
  # Del redirect  
  else 
    if [ w${DEBUG} != w ]; then
      echo "IP deleted - ${IP}"
    fi;
    /sbin/ipfw table ${MSGS_TABLE_NUM} delete ${IP}
  fi;

else
#If OS linux


fi;


#Multiservers starter
##!/bin/sh#
#
#ACTION=$1
#UID=$2
#IP=$3
#
#echo "${ACTION} ${UID}"
#
#for host in 192.168.17.2 192.168.17.4; do
#
#if [ "${ACTION}" = "add" ]; then
#  /usr/bin/ssh -i /usr/abills/Certs/id_dsa.abills_admin -o StrictHostKeyChecking=no -q abills_admin@${host}  "/usr/local/bin/sudo /usr/abills/misc/msgs_filter.sh ${ACTION} ${UID}"
#else
#  /usr/bin/ssh -i /usr/abills/Certs/id_dsa.abills_admin -o StrictHostKeyChecking=no -q abills_admin@${host} "/usr/local/bin/sudo /usr/abills/misc/msgs_filter.sh
# ${IP}";
#fi;
#
#done;
