#!/bin/sh
# ABillS Firefall Managment Program for Linux
#
#***********************************************************************
# /etc/rc.conf
#
# abills_firewall="YES"          enable ABillS Firewall
#
# abills_shaper_enable="YES"     enable shapper
#
# abills_shaper2_enable="YES"    enable shapper with mangle
#
# abills_nas_id=""               ABillS NAS ID default 1
#
# abills_ip_sessions=""          ABIllS IP SEssions limit
#
# abills_nat="EXTERNAL_IP:INTERNAL_IPS:NAT_IF" - Enable abills nat
#
# abills_dhcp_shaper=""  (bool)  Set to "NO" by default.
#                                Enable ipoe_shaper
#
# abills_dhcp_shaper_nas_ids=""  Set nas ids for shapper, Default: all nas servers
#
# abills_mikrotik_shaper=""      NAS IDS
#
#IPN Section configuration
#
# abills_ipn_nas_id=""           ABillS IPN NAS ids, Enable IPN firewall functions
#
# abills_ipn_if="eth0,eth1"      IPN Shapper interface
#
#Other
#
# abills_squid_redirect=""      Redirect traffic to squid
#
# abills_neg_deposit=""         Enable neg deposit redirect
#
# abills_neg_deposit_speed="512" Set default speed for negative deposit


### BEGIN INIT INFO
# Provides:          shaper_start
# Required-Start:    $remote_fs $network $syslog
# Should-Start:      $time mysql slapd postgresql samba krb5-kdc
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Radius Daemon
# Description:       Extensible, configurable radius daemon
### END INIT INFO

set -e

. /lib/lsb/init-functions

PROG="shaper_start"
DESCR="shaper_start"

VERSION=1.02 
. /etc/rc.conf

name="abills_shaper" 

if [ x${abills_shaper_enable} = x ]; then
  name="abills_nat"
  abills_nat_enable=YES; 
fi;

TC="/sbin/tc"
IPT=/sbin/iptables 
SED=/bin/sed 
BILLING_DIR=/usr/abills


#Negative deposit forward (default: )
FWD_WEB_SERVER_IP=127.0.0.1;
#Your user portal IP 
USER_PORTAL_IP=${abills_portal_ip} 
EXTERNAL_INTERFACE=`/sbin/ip r | awk '/default/{print $5}'`



#**********************************************************
#
#**********************************************************
all_rulles(){
  ACTION=$1

if [ x${abills_ipn_if} != x ]; then
  IPN_INTERFACES=`echo ${abills_ipn_if} | sed 's/,/ /g'`
fi;

abills_iptables
abills_shaper 
abills_shaper2
abills_ipn 
abills_nat 
neg_deposit

}


#**********************************************************
#IPTABLES RULES
#**********************************************************
abills_iptables() {

if [ x${abills_firewall} = x ]; then
  return 0;
fi;

echo "ABillS Iptables ${ACTION}"

if [ x${ACTION} = xstart ];then
$IPT -P INPUT DROP
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD DROP

# Включить на сервере интернет
$IPT -A INPUT -i lo -j ACCEPT
# Разрешить ping к серверу доступа
$IPT -A INPUT -p icmp -m icmp -j ACCEPT
# Разрешить SSH запросы к серверу
$IPT -A INPUT -p TCP -s 0/0  --dport 22 -j ACCEPT
# Разрешить DNS запросы к серверу
$IPT -A INPUT -p TCP -s 0/0  --sport 53 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --dport 53 -j ACCEPT
# Разрешить DHCP запросы к серверу
$IPT -A INPUT -p TCP -s 0/0  --sport 67 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --dport 67 -j ACCEPT
# Доступ к странице авторизации 
$IPT -A INPUT -p TCP -s 0/0  --sport 80 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --dport 80 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --sport 9443 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --dport 9443 -j ACCEPT
$IPT -A FORWARD -p tcp -m tcp -s 0/0 --dport 80 -j ACCEPT
$IPT -A FORWARD -p tcp -m tcp -s 0/0 --dport 9443 -j ACCEPT

if [ x${abills_ipn_if} != x ]; then
  IPN_INTERFACES=`echo ${abills_ipn_if} | sed 's/,/ /g'`

  # Перенаправление IPN клиентов
  for REDIRECT_IPN in ${IPN_INTERFACES}; do
    REDIRECT_POOL=`ip r |grep " ${REDIRECT_IPN} " | awk '{ print $1 }'`
    $IPT -t nat -A PREROUTING -s ${REDIRECT_POOL} -p tcp --dport 80 -j REDIRECT --to-ports 80
    $IPT -t nat -A PREROUTING -s ${REDIRECT_POOL} -p tcp --dport 443 -j REDIRECT --to-ports 80
    echo "Redirect UP ${REDIRECT_POOL}"
  done
else
 echo "unknown ABillS IPN IFACES"
fi;


elif [ x${ACTION} = xstop ]; then
  # Разрешаем всё и всем
  $IPT -P INPUT ACCEPT
  $IPT -P OUTPUT ACCEPT
  $IPT -P FORWARD ACCEPT

  # Чистим все правила
  $IPT -F
  $IPT -F -t nat
  $IPT -F -t mangle
  $IPT -X
  $IPT -X -t nat
  $IPT -X -t mangle
fi;
}



#**********************************************************
# Abills Shapper
#**********************************************************
abills_shaper() { 

  if [ x${abills_shaper_enable} = xNO ]; then
    return 0;
  elif [ x${abills_shaper_enable} = xNAT ]; then
    return 0;
  elif [ x${abills_shaper_enable} = x ]; then
    return 0;
  fi;

echo "ABillS Shapper ${ACTION}"

if [ x${ACTION} = xstart ]; then
  for INTERFACE in ${IPN_INTERFACES}; do
    TCQA="${TC} qdisc add dev ${INTERFACE}"
    TCQD="${TC} qdisc del dev ${INTERFACE}"

    $TCQD root &>/dev/null
    $TCQD ingress &>/dev/null

    $TCQA root handle 1: htb
    $TCQA handle ffff: ingress

    echo "Shaper UP ${INTERFACE}"
    
    ${IPT} -A FORWARD -j DROP -i ${INTERFACE}
  done
elif [ x${ACTION} = xstop ]; then
  for INTERFACE in ${IPN_INTERFACES}; do
    TCQA="${TC} qdisc add dev ${INTERFACE}"
    TCQD="${TC} qdisc del dev ${INTERFACE}"

    $TCQD root &>/dev/null
    $TCQD ingress &>/dev/null

    echo "Shaper DOWN ${INTERFACE}"
  done
elif [ x${ACTION} = xstatus ]; then
  for INTERFACE in ${IPN_INTERFACES}; do
    echo "Internal: ${INTERFACE}"
    ${TC} class show dev ${INTERFACE}
    ${TC} qdisc show dev ${INTERFACE}
  done
fi;


}

#**********************************************************
# Abills Shapper
# With mangle support
#**********************************************************
abills_shaper2() { 

  if [ x${abills_shaper2_enable} = xNO ]; then
    return 0;
  elif [ x${abills_shaper2_enable} = x ]; then
    return 0;
  fi;

echo "ABillS Shapper 2 ${ACTION}"

SPEEDUP=100mbit
SPEEDDOWN=100mbit

if [ x${ACTION} = xstart ]; then
  ${IPT} -t mangle --flush

  ${TC} qdisc add dev ${EXTERNAL_INTERFACE} root handle 1: htb
  ${TC} class add dev ${EXTERNAL_INTERFACE} parent 1: classid 1:1 htb rate $SPEEDDOWN ceil $SPEEDDOWN

  for INTERFACE in ${IPN_INTERFACES}; do
    ${TC} qdisc add dev ${INTERFACE} root handle 1: htb
    ${TC} class add dev ${INTERFACE} parent 1: classid 1:1 htb rate $SPEEDUP ceil $SPEEDUP

    ${IPT} -A FORWARD -j DROP -i ${INTERFACE}
    echo "Shaper UP ${INTERFACE}"
  done
elif [ x${ACTION} = xstop ]; then
  ${IPT} -t mangle --flush
  ${TC} qdisc del dev ${EXTERNAL_INTERFACE} root handle 1: htb
  for INTERFACE in ${IPN_INTERFACES}; do
    ${TC} qdisc del dev ${INTERFACE} root handle 1: htb
    echo "Shaper DOWN ${INTERFACE}"
  done
elif [ x${ACTION} = xstatus ]; then
  echo "External: ${EXTERNAL_INTERFACE}";  
  ${TC} class show dev ${EXTERNAL_INTERFACE}
  for INTERFACE in ${IPN_INTERFACES}; do
    echo "Internal: ${INTERFACE}"
    ${TC} class show dev ${INTERFACE}
  done
fi;
}

#**********************************************************
#Ipn Sections
# Enable IPN
#**********************************************************
abills_ipn() {

if [ x${abills_ipn_nas_id} = x ]; then
  return 0;
fi;

if [ x${ACTION} = xstart ]; then
  echo "Enable users IPN"

  #echo 1 > /proc/sys/net/ipv4/ip_forward
  sysctl -w net.ipv4.ip_forward=1

  ${BILLING_DIR}/libexec/periodic monthly MODULES=Ipn SRESTART=1 NO_ADM_REPORT=1 NAS_IDS="${abills_ipn_nas_id}"
  
  if [ x"${abills_ipn_allow_ip}" != x ]; then
    echo "Enable allow ips ${abills_ipn_allow_ip}";
    for INTERFACE in ${IPN_INTERFACES} ; do
      for IP in ${abills_ipn_allow_ip} ; do
        ${IPT} -I FORWARD  -d ${IP} -j ACCEPT -i ${INTERFACE};
        ${IPT} -I FORWARD  -s ${IP} -j ACCEPT -i ${INTERFACE};
        if [ x"${abills_nat}" != x ]; then
          ${IPT} -t nat -I PREROUTING 1 -d ${IP} -j ACCEPT;
        fi;
      done;
    done;
  fi;

fi;
}


#**********************************************************
# Start custom shapper rules
#**********************************************************


#**********************************************************
#NAT Section
#**********************************************************
abills_nat() {

  if [ x"${abills_nat}" = x ]; then
    return 0;
  fi;

  echo "ABillS NAT ${ACTION}"
  
  if [ x${ACTION} = xstatus ]; then
    ${IPT} -t nat -L
    return 0;
  fi;
  
  # NAT External IP
  NAT_IPS=`echo ${abills_nat} | awk -F: '{ print $1 }'`;
  # Fake net
  FAKE_NET=`echo ${abills_nat} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
  #NAT IF
  NAT_IF=`echo ${abills_nat} | awk -F: '{ print $3 }'`;
  echo  "NAT: $NAT_IPS | $FAKE_NET $NAT_IF"
  if [ x${NAT_IPS} = x ]; then
    NAT_IPS=all
  fi;
  # nat configuration

  for IP in ${NAT_IPS}; do

    if [ w${ACTION} = wstart ]; then 
     for IP_NAT in ${FAKE_NET}; do
      ${IPT} -t nat -A POSTROUTING -s ${IP_NAT} -j SNAT --to-source ${IP}
      echo "Enable NAT for ${IP_NAT}"
     done;
    fi;
  done;
    if [ x${ACTION} = xstop ]; then
      ${IPT} -F -t nat
      ${IPT} -X -t nat
      echo "Disable NAT"
    fi;

}


#**********************************************************
#Neg deposit FWD Section
#**********************************************************
neg_deposit() {
  
  if [ x"${abills_neg_deposit}" = x ]; then
    return 0;
  fi;

  echo "NEG_DEPOSIT"

  if [ "${abills_neg_deposit}" = "YES" ]; then
    USER_NET="0.0.0.0/0"
  else
    # Portal IP
    PORTAL_IP=`echo ${abills_neg_deposit} | awk -F: '{ print $1 }'`;
    # Fake net
    USER_NET=`echo ${abills_neg_deposit} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
    # Users IF
    USER_IF=`echo ${abills_neg_deposit} | awk -F: '{ print $3 }'`;
    echo  "$PORTAL_IP $USER_NET $USER_IF"
  fi;


  for IP in ${USER_NET}; do  
    ${IPT} -t nat -A PREROUTING -s ${IP} -p tcp --dport 80 -j REDIRECT --to-ports 80 -i ${USER_IF}
  done;

  
}


#**********************************************************
#
#**********************************************************
fw_gre () {

  INTERFACE="-i eth3"

  iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
  iptables -A INPUT -i ${INTERFACE} -p tcp -m tcp --dport 53 -j ACCEPT
  iptables -A INPUT -i ${INTERFACE} -p udp -m udp --dport 53 -j ACCEPT
  iptables -A INPUT -i ${INTERFACE} -p tcp -m tcp --dport 9443 -j ACCEPT
  iptables -A INPUT -i ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A INPUT -i ${INTERFACE} -p tcp --dport 1723 -j ACCEPT
  iptables -A INPUT -i ${INTERFACE} -p gre -j ACCEPT
  iptables -A INPUT -i ${INTERFACE} -p icmp -j ACCEPT
  iptables -A INPUT -i ${INTERFACE} -j DROP
  iptables -A OUTPUT -j ACCEPT

}

#############################Скрипт################################
case "$1" in start) echo -n "START : $name"
      echo ""
	    all_rulles start
	    echo "."
	    ;; 
	stop) echo -n "STOP : $name"
	    echo ""
	    all_rulles stop
	    echo "."
	    ;; 
	restart) echo -n "RESTART : $name"
	    echo ""
	    all_rulles stop
	    all_rulles start
	    echo "."
	    ;;
	status) echo -n "STATUS : $name"
	    echo ""
	    all_rulles status
	    echo "."
	    ;;
    *) echo "Usage: /etc/init.d/shapper_start.sh
 start|stop|status|restart|clear"
    exit 1
    ;; 
    esac 


exit 0
