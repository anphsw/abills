#!/bin/bash
# ABillS Firefall Managment Program for Linux
#
#***********************************************************************
# /etc/rc.conf
#
#####Включить фаервол#####
#abills_firewall="YES"
#
#####Включить старый шейпер#####
#abills_shaper_enable="YES"
#
#####Включить новый шейпер#####
#abills_shaper2_enable="YES"
#
#####Включить шейпер IPMARK#####
#abills_shaper3_enable="YES"
#
#####Включить шейпер IPTABLES RATELIMIT#####
#abills_shaper_iptables_enable="YES"
#abills_shaper_iptables_local_ips="сеть1;сеть2"
#Добавить правила
#echo @+10.0.0.5 1000000 > /proc/net/ipt_ratelimit/world-in
#echo @+10.0.0.5 1000000 > /proc/net/ipt_ratelimit/world-out
#echo @+10.0.0.5 10000000 > /proc/net/ipt_ratelimit/local-in
#echo @+10.0.0.5 10000000 > /proc/net/ipt_ratelimit/local-out
#Удалить правила
#echo @-10.0.0.5 > /proc/net/ipt_ratelimit/world-in
#echo @-10.0.0.5 > /proc/net/ipt_ratelimit/world-out
#echo @-10.0.0.5 > /proc/net/ipt_ratelimit/local-in
#echo @-10.0.0.5 > /proc/net/ipt_ratelimit/local-out
#
#####Указать номера нас серверов модуля IPN#####
#abills_ipn_nas_id=""
#
#####Включить NAT "Внешний_IP:подсеть;Внешний_IP:подсеть;"#####
#abills_nat=""
#
#####Втлючть FORWARD на определённую подсеть#####
#abills_ipn_allow_ip=""
#
#####Пул перенаправления на страницу заглушку#####
#abills_redirect_clients_pool=""
#
#####Внутренний IP (нужен для нового шейпера)#####
#abills_ipn_if=""
#
#####Включить IPoE шейпер#####
#abills_dhcp_shaper="YES"
#
#####Указать IPoE NAS серверов "nas_id;nas_id;nas_id" #####
#abills_dhcp_shaper_nas_ids="";
#
#####Ожидать загрузку сервера с базой#####
#abills_mysql_server_status="YES"
#
#####Указать адрес сервера mysql#####
#abills_mysql_server=""
#
#####Привязать серевые интерфейсы к ядрам#####
#abills_irq2smp="YES"
#
#####Включить ipt_NETFLOW#####
#ipt_netflow="YES"
#
#####IP Unnumbered#####
#####Указать общую подсеть раздаваемую абонентам#####
#abills_unnumbered="YES"
#####Указать общую подсеть раздаваемую абонентам "сеть1;сеть2"#####
#abills_unnumbered_net="10.0.0.0/22"
#####Указать шлюз сети для абонентов "шлюз1;шлюз2"#####
#abills_unnumbered_gw="10.0.0.1"
#abills_unnumbered_iface="vlan740-794,vlan800-998"
#
#abills_custom_rules=""
#
#Load to start System
#sudo update-rc.d shaper_start.sh start 99 2 3 4 5 . stop 01 0 1 6 .
#
#Unload to start System
#sudo update-rc.d -f shaper_start.sh remove
#

set -e

#. /lib/lsb/init-functions

PROG="shaper_start"
DESCR="shaper_start"

VERSION=1.51
if [[ -f /etc/rc.conf ]]; then
. /etc/rc.conf
else
  echo 'File not exist /etc/rc.conf';
fi;

: ${abills_shaper_enable="NO"}
: ${abills_shaper_if=""}
: ${abills_nas_id=""}
: ${abills_ip_sessions=""}

: ${abills_nat=""}
: ${abills_multi_gateway=""}

: ${abills_dhcp_shaper="NO"}
: ${abills_dhcp_shaper_log=""}
: ${abills_dhcp_shaper_nas_ids=""}
: ${abills_neg_deposit="NO"}
: ${abills_neg_deposit_speed=""}
: ${abills_neg_deposit_fwd_ip="127.0.0.1"}
: ${abills_portal_ip="me"}
: ${abills_mikrotik_shaper=""}
: ${abills_squid_redirect="NO"}
: ${firewall_type=""}

: ${abills_ipn_nas_id=""}
: ${abills_ipn_if=""}
: ${abills_ipn_allow_ip=""}

: ${abills_netblock="NO"}
: ${abills_netblock_redirect_ip=""}
: ${abills_netblock_type=""}

#Extra functions
: ${abills_mysql_server_status="NO"}
: ${abills_mysql_server=""}
: ${abills_unnumbered="NO"}
: ${abills_unnumbered_net=""}
: ${abills_unnumbered_iface=""}
: ${abills_unnumbered_gw=""}
: ${abills_irq2smp="NO"}
: ${abills_redirect_clients_pool=""}
: ${abills_iptables_custom=""}
: ${abills_shaper2_enable="NO"}
: ${abills_shaper3_enable="NO"}
: ${abills_allow_dhcp_port_67=""}
: ${abills_firewall=""}

: ${abills_shaper_iptables_enable=""}
: ${abills_custom_rules=""}
: ${ipt_netflow=""}
: ${abills_shaper_iptables_local_ips=""}
name="abills_shaper" 

if [[ x${abills_shaper_enable} = x ]]; then
  name="abills_nat"
  abills_nat_enable=YES; 
fi;

TC="/sbin/tc"
IPT=/sbin/iptables 
SED=/bin/sed 
IPSET=/usr/sbin/ipset
BILLING_DIR=/usr/abills

if [[ ! -f "${TC}" ]]; then
  TC=`which tc`;
fi;

if [[ ! -f "${IPT}" ]]; then
  IPT=`which iptables`;
fi;

if [[ ! -f "${SED}" ]]; then
  SED=`which sed`;
fi;

if [[ ! -f "${IPSET}" ]]; then
  IPSET=`which ipset`;
fi;


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

if [[ x${abills_ipn_if} != x ]]; then
IPN_INTERFACES="";
ifaces=`echo ${abills_ipn_if} | sed 'N;s/\n/ /' |sed 's/,/ /g'`
  for i in ${ifaces}; do

    if [[ ${i} =~ - ]]; then
          vlan_name=`echo ${i}|sed 's/vlan//'`
          IFS='-' read -a start_stop <<< "$vlan_name"
          for cur_iface in `seq ${start_stop[0]} ${start_stop[1]}`;
          do
              IPN_INTERFACES="$IPN_INTERFACES vlan${cur_iface}"
          done
      else
              IPN_INTERFACES="$IPN_INTERFACES $i"
      fi
  done
fi;
if [[ x${abills_dhcp_shaper_nas_ids} != x ]]; then
NAS_IDS="NAS_IDS=";
nas_ids=`echo ${abills_dhcp_shaper_nas_ids} | sed 'N;s/\n/ /' |sed 's/,/ /g'`
  for i in ${nas_ids}; do

    if [[ ${i} =~ - ]]; then
          IFS='-' read -a start_stop <<< "$i"
          for cur_nas_id in `seq ${start_stop[0]} ${start_stop[1]}`;
          do
              NAS_IDS="$NAS_IDS${cur_nas_id};"
          done
      else
              NAS_IDS="$NAS_IDS$i;"
      fi
  done
fi;
ip_unnumbered
#check_server
abills_iptables
abills_nat
abills_shaper
abills_shaper2
abills_shaper3
#abills_shaper_iptables
abills_ipn
abills_dhcp_shaper
#abills_custom_rule
neg_deposit
irq2smp
}


#**********************************************************
#IPTABLES RULES
#**********************************************************
abills_iptables() {

if [[ x${abills_firewall} = x ]]; then
  return 0;
fi;

echo "ABillS Iptables ${ACTION}"
sysctl -w net.ipv4.ip_forward=1
if [[ x${ACTION} = xstart ]];then
${IPT} -P INPUT ACCEPT
${IPT} -P OUTPUT ACCEPT
${IPT} -P FORWARD ACCEPT
${IPT} -t nat -I PREROUTING -j ACCEPT
# Включить на сервере интернет
${IPT} -A INPUT -i lo -j ACCEPT
# Пропускать все уже инициированные соединения, а также дочерние от них
${IPT} -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
# Разрешить SSH запросы к серверу
${IPT} -A INPUT -p TCP -s 0/0  --dport 22 -j ACCEPT
# Разрешить TELNET запросы к серверу
${IPT} -A INPUT -p TCP -s 0/0  --dport 23 -j ACCEPT
# Разрешить ping к серверу доступа
${IPT} -A INPUT -p icmp -m icmp --icmp-type any -j ACCEPT
# Разрешить DNS запросы к серверу
${IPT} -A INPUT -p UDP -s 0/0  --dport 53 -j ACCEPT
# Разрешить DHCP запросы к серверу
${IPT} -A INPUT -p UDP -s 0/0  --dport 68 -j ACCEPT
${IPT} -A INPUT -p UDP -s 0/0  --dport 67 -j ACCEPT
#Запретить исходящий 25 порт
${IPT} -I OUTPUT -p tcp -m tcp --sport 25 -j DROP
${IPT} -I OUTPUT -p tcp -m tcp --dport 25 -j DROP
# Доступ к странице авторизации
${IPT} -A INPUT -p TCP -s 0/0  --dport 80 -j ACCEPT
${IPT} -A INPUT -p TCP -s 0/0  --dport 443 -j ACCEPT
${IPT} -A INPUT -p TCP -s 0/0  --dport 9443 -j ACCEPT
${IPT} -I INPUT -p udp -m udp --dport 161 -j ACCEPT
${IPT} -I INPUT -p udp -m udp --dport 162 -j ACCEPT

# MYSQL
${IPT} -A INPUT -p TCP -s 0/0  --sport 3306 -j ACCEPT
${IPT} -A INPUT -p TCP -s 0/0  --dport 3306 -j ACCEPT

if [[ x${ipt_netflow} = xYES ]];then
  ${IPT} -A FORWARD -j NETFLOW;
fi;

${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 80 -j ACCEPT
${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 443 -j ACCEPT
${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 9443 -j ACCEPT


# USERS
  allownet=`${IPSET} -L |grep allownet|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${allownet}" = x ]]; then
    echo "ADD allownet"
      ${IPSET} -N allownet nethash
    fi;

# SET
  allowip=`${IPSET} -L |grep allowip|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${allowip}" = x ]]; then
    echo "ADD allowip"
      ${IPSET} -N allowip iphash
    fi;

${IPT} -A FORWARD -m set --match-set allownet src -j ACCEPT
${IPT} -A FORWARD -m set --match-set allownet dst -j ACCEPT
${IPT} -t nat -A PREROUTING -m set --match-set allownet src -j ACCEPT

${IPT} -A FORWARD -m set --match-set allowip src -j ACCEPT
${IPT} -A FORWARD -m set --match-set allowip dst -j ACCEPT
${IPT} -t nat -A PREROUTING -m set --match-set allowip src -j ACCEPT

if [[ x"${abills_redirect_clients_pool}" != x ]]; then
  # Перенаправление клиентов
    REDIRECT_POOL=`echo ${abills_redirect_clients_pool}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
	echo "${REDIRECT_POOL}"
	for REDIRECT_IPN_POOL in ${REDIRECT_POOL}; do
	    ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 80 -j REDIRECT --to-ports 80
	    ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 443 -j REDIRECT --to-ports 80
	    ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 9443 -j REDIRECT --to-ports 80
        echo "Redirect UP ${REDIRECT_IPN_POOL}"
        done
else
 echo "unknown ABillS IPN IFACES"
fi;

  if [[ x"${abills_ipn_allow_ip}" != x ]]; then
    ABILLS_ALLOW_IP=`echo ${abills_ipn_allow_ip}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
    echo "Enable allow ips ${ABILLS_ALLOW_IP}";
      for IP in ${ABILLS_ALLOW_IP} ; do
        ${IPT} -I FORWARD  -d ${IP} -j ACCEPT;
        ${IPT} -I FORWARD  -s ${IP} -j ACCEPT;
        if [[ x"${abills_nat}" != x ]]; then
          ${IPT} -t nat -I PREROUTING -s ${IP} -j ACCEPT;
          ${IPT} -t nat -I PREROUTING -d ${IP} -j ACCEPT;
          ${IPT} -t nat -I POSTROUTING -s ${IP} -j ACCEPT;
          ${IPT} -t nat -I POSTROUTING -d ${IP} -j ACCEPT;
        fi;
      done;
else
 echo "unknown ABillS IPN ALLOW IP"
fi;


elif [[ x${ACTION} = xstop ]]; then
  # Разрешаем всё и всем
  ${IPT} -P INPUT ACCEPT
  ${IPT} -P OUTPUT ACCEPT
  ${IPT} -P FORWARD ACCEPT

  # Чистим все правила
  ${IPT} -F
  ${IPT} -F -t nat
  ${IPT} -F -t mangle
  ${IPT} -X
  ${IPT} -X -t nat
  ${IPT} -X -t mangle

  allowip=`${IPSET} -L |grep allowip|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${allowip}" != x ]]; then
    echo "DELETE allowip"
      ${IPSET} destroy allowip
    fi;
  allownet=`${IPSET} -L |grep allownet|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${allownet}" != x ]]; then
    echo "DELETE allownet"
      ${IPSET} destroy allownet
    fi;

elif [[ x${ACTION} = xstatus ]]; then
${IPT} -S
fi;

}



#**********************************************************
# Abills Shapper
#**********************************************************
abills_shaper() { 

  if [[ x${abills_shaper_enable} = xNO ]]; then
    return 0;
  elif [[ x${abills_shaper_enable} = xNAT ]]; then
    return 0;
  elif [[ x${abills_shaper_enable} = x ]]; then
    return 0;
  fi;

echo "ABillS Shapper ${ACTION}"

if [[ x${ACTION} = xstart ]]; then
  for INTERFACE in ${IPN_INTERFACES}; do
    TCQA="${TC} qdisc add dev ${INTERFACE}"
    TCQD="${TC} qdisc del dev ${INTERFACE}"

    ${TCQD} root &>/dev/null
    ${TCQD} ingress &>/dev/null

    ${TCQA} root handle 1: htb
    ${TCQD} handle ffff: ingress

    echo "Shaper UP ${INTERFACE}"
    
    ${IPT} -A FORWARD -j DROP -i ${INTERFACE}
  done
elif [[ x${ACTION} = xstop ]]; then
  for INTERFACE in ${IPN_INTERFACES}; do
    TCQA="${TC} qdisc add dev ${INTERFACE}"
    TCQD="${TC} qdisc del dev ${INTERFACE}"

    ${TCQD} root &>/dev/null
    ${TCQD} ingress &>/dev/null

    echo "Shaper DOWN ${INTERFACE}"
  done
elif [[ x${ACTION} = xstatus ]]; then
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

  if [[ x${abills_shaper2_enable} = xNO ]]; then
    return 0;
  elif [[ x${abills_shaper2_enable} = x ]]; then
    return 0;
  fi;

echo "ABillS Shapper 2 ${ACTION}"

SPEEDUP=1000mbit
SPEEDDOWN=1000mbit

if [[ x${ACTION} = xstart ]]; then
  ${IPT} -t mangle --flush
  ${TC} qdisc add dev ${EXTERNAL_INTERFACE} root handle 1: htb
  ${TC} class add dev ${EXTERNAL_INTERFACE} parent 1: classid 1:1 htb rate ${SPEEDDOWN} ceil ${SPEEDDOWN}

  for INTERFACE in ${IPN_INTERFACES}; do
    ${TC} qdisc add dev ${INTERFACE} root handle 1: htb
    ${TC} class add dev ${INTERFACE} parent 1: classid 1:1 htb rate ${SPEEDUP} ceil ${SPEEDUP}

#    ${IPT} -A FORWARD -j DROP -i ${INTERFACE}
    echo "Shaper UP ${INTERFACE}"
  done
elif [[ x${ACTION} = xstop ]]; then
  ${IPT} -t mangle --flush
  EI=`tc qdisc show dev ${EXTERNAL_INTERFACE} |grep htb | sed 's/ //g'`
  if [[ x${EI} != x ]]; then
    ${TC} qdisc del dev ${EXTERNAL_INTERFACE} root handle 1: htb 
  fi;
  for INTERFACE in ${IPN_INTERFACES}; do
    II=`tc qdisc show dev ${INTERFACE} |grep htb | sed 's/ //g'`
  if [[ x${II} != x ]]; then
    ${TC} qdisc del dev ${INTERFACE} root handle 1: htb 
    echo "Shaper DOWN ${INTERFACE}"
  fi;
  done
elif [[ x${ACTION} = xstatus ]]; then
  echo "External: ${EXTERNAL_INTERFACE}";  
  ${TC} class show dev ${EXTERNAL_INTERFACE}
  for INTERFACE in ${IPN_INTERFACES}; do
    echo "Internal: ${INTERFACE}"
    ${TC} class show dev ${INTERFACE}
  done
fi;
}
#**********************************************************
# Abills Shapper
# With IPMARK support
#**********************************************************
abills_shaper3() {

  if [[ x${abills_shaper3_enable} = xNO ]]; then
    return 0;
  elif [[ x${abills_shaper3_enable} = x ]]; then
    return 0;
  fi;
echo "ABillS Shapper 3 ${ACTION}"
if [[ x${ACTION} = xstart ]]; then
  ${IPT} -t mangle -A POSTROUTING -o ${EXTERNAL_INTERFACE} -j IPMARK --addr src --and-mask 0xffff --or-mask 0x10000
  ${TC} qdisc add dev ${EXTERNAL_INTERFACE} root handle 1: htb
  ${TC} filter add dev ${EXTERNAL_INTERFACE} parent 1:0 protocol ip fw

  for INTERFACE in ${IPN_INTERFACES}; do
    ${IPT} -t mangle -A POSTROUTING -o ${INTERFACE} -j IPMARK --addr dst --and-mask 0xffff --or-mask 0x10000
    ${TC} qdisc add dev ${INTERFACE} root handle 1: htb
    ${TC} filter add dev ${INTERFACE} parent 1:0 protocol ip fw

    echo "Shaper 3 UP ${INTERFACE}"
  done
elif [[ x${ACTION} = xstop ]]; then
  ${IPT} -t mangle --flush
  EI=`tc qdisc show dev ${EXTERNAL_INTERFACE} |grep htb | sed 's/ //g'`
  if [[ x${EI} != x ]]; then
    ${TC} qdisc del dev ${EXTERNAL_INTERFACE} root
  fi;
  for INTERFACE in ${IPN_INTERFACES}; do
    II=`tc qdisc show dev ${INTERFACE} |grep htb | sed 's/ //g'`
  if [[ x${II} != x ]]; then
    ${TC} qdisc del dev ${INTERFACE} root
    echo "Shaper DOWN ${INTERFACE}"
  fi;
  done
elif [[ x${ACTION} = xstatus ]]; then
  echo "External: ${EXTERNAL_INTERFACE}";
  ${TC} qdisc show dev ${EXTERNAL_INTERFACE}
  for INTERFACE in ${IPN_INTERFACES}; do
    echo "Internal: ${INTERFACE}"
    ${TC} qdisc show dev ${INTERFACE}
  done
fi;
}
#**********************************************************
# Abills Shapper
# With ipt-ratelimit support
#**********************************************************
abills_shaper_iptables() {
  if [[ x${abills_shaper_iptables_enable} = xNO ]]; then
    return 0;
  elif [[ x${abills_shaper_iptables_enable} = x ]]; then
    return 0;
  fi;
  echo "ABillS Shapper IPTABLES ${ACTION}"
  if [[ x${ACTION} = xstart ]]; then

    LOCAL_IP=`${IPSET} -L |grep LOCAL_IP|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${LOCAL_IP}" = x ]]; then
      echo "ADD LOCAL_IP TO IPSET"
      ${IPSET} -N LOCAL_IP iphash
    fi;
    LOCAL_NET=`${IPSET} -L |grep LOCAL_NET|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${LOCAL_NET}" = x ]]; then
      echo "ADD LOCAL_NET TO IPSET"
      ${IPSET} -N LOCAL_NET nethash
    fi;
    UKRAINE=`${IPSET} -L |grep UKRAINE|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${UKRAINE}" = x ]]; then
      echo "ADD UKRAINE TO IPSET"
      ${IPSET} -N UKRAINE nethash
    fi;

    ${IPT} -I FORWARD -m ratelimit --ratelimit-set world-out --ratelimit-mode src -j DROP
    ${IPT} -I FORWARD -m ratelimit --ratelimit-set world-in --ratelimit-mode dst -j DROP

    LOCAL=`${IPT} -S |grep '\-N LOCAL'|awk -F" "  '{ print $2 }'`
    if [[ x"${LOCAL}" = x ]]; then
      ${IPT} -N LOCAL
    fi;
    UAIX=`${IPT} -S |grep '\-N UA-IX'|awk -F" "  '{ print $2 }'`
    if [[ x"${UAIX}" = x ]]; then
      ${IPT} -N UA-IX
    fi;

    ${IPT} -I UA-IX -m ratelimit --ratelimit-set ua-ix-out --ratelimit-mode src -j DROP
    ${IPT} -I UA-IX -m ratelimit --ratelimit-set ua-ix-in --ratelimit-mode dst -j DROP
    ${IPT} -I FORWARD -m set --match-set UKRAINE src -j UA-IX;
    ${IPT} -I FORWARD -m set --match-set UKRAINE dst -j UA-IX;

    ${IPT} -I LOCAL -m ratelimit --ratelimit-set local-out --ratelimit-mode src -j DROP
    ${IPT} -I LOCAL -m ratelimit --ratelimit-set local-in --ratelimit-mode dst -j DROP
    ${IPT} -I FORWARD -m set --match-set LOCAL_IP src -j LOCAL;
    ${IPT} -I FORWARD -m set --match-set LOCAL_IP dst -j LOCAL;
    ${IPT} -I FORWARD -m set --match-set LOCAL_NET src -j LOCAL;
    ${IPT} -I FORWARD -m set --match-set LOCAL_NET dst -j LOCAL;
    if [[ x"${abills_shaper_iptables_local_ips}" != x ]]; then
      LOCAL_IPS=`echo ${abills_shaper_iptables_local_ips}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
      for LOCAL_IP in ${LOCAL_IPS}; do
        if [[ ${LOCAL_IP} =~  ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || [[ ${LOCAL_IP} =~  ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/32$ ]]; then
          echo "ADD ${LOCAL_IP} TO LOCAL_IP"
          ${IPSET} -A LOCAL_IP ${LOCAL_IP} 
        elif [[ ${LOCAL_IP} =~  ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{2}$ ]]; then
        echo "ADD ${LOCAL_IP} TO LOCAL_NET"
          ${IPSET} -A LOCAL_NET ${LOCAL_IP}
        fi
#        ${IPT} -I FORWARD -d ${LOCAL_IP} -j LOCAL
      done
    fi;

  elif [[ x${ACTION} = xstop ]]; then
    LOCAL_IP=`${IPSET} -L |grep LOCAL_IP|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${LOCAL_IP}" != x ]]; then
      echo "DELETE SET LOCAL_IP"
      ${IPSET} destroy LOCAL_IP
    fi;
    LOCAL_NET=`${IPSET} -L |grep LOCAL_NET|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${LOCAL_NET}" != x ]]; then
      echo "DELETE SET LOCAL_NET"
      ${IPSET} destroy LOCAL_NET
    fi;
    UKRAINE=`${IPSET} -L |grep UKRAINE|sed 's/ //'|awk -F: '{ print $2 }'`
    if [[ x"${UKRAINE}" != x ]]; then
      echo "DELETE SET UKRAINE"
      ${IPSET} destroy UKRAINE
    fi;
    LOCAL=`${IPT} -S |grep '\-N LOCAL'|awk -F" "  '{ print $2 }'`
    if [[ x"${LOCAL}" != x ]]; then
      ${IPT} -X LOCAL
    fi;
    UAIX=`${IPT} -S |grep '\-N UA-IX'|awk -F" "  '{ print $2 }'`
    if [[ x"${UAIX}" != x ]]; then
      ${IPT} -X UA-IX
    fi;
  fi;

}
#**********************************************************
#Ipn Sections
# Enable IPN
#**********************************************************
abills_ipn() {

if [[ x${abills_ipn_nas_id} = x ]]; then
  return 0;
fi;

if [[ x${ACTION} = xstart ]]; then
  echo "Enable users IPN"

  ${BILLING_DIR}/libexec/periodic monthly MODULES=Ipn SRESTART=1 NO_ADM_REPORT=1 NO_RULE NAS_IDS="${abills_ipn_nas_id}"

fi;
}


#**********************************************************
# Start custom rules
#**********************************************************
abills_custom_rule() {
if [[ x"${abills_custom_rules}" != x ]]; then
    CUSTOM_RULES=`echo ${abills_custom_rules}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
        for CUSTOM_RULE in ${CUSTOM_RULES}; do
          echo "${CUSTOM_RULE}"
          ${IPT} ${CUSTOM_RULE}
        done
fi;

}

#**********************************************************
#NAT Section
#**********************************************************
abills_nat() {

  if [[ x"${abills_nat}" = x ]]; then
    return 0;
  fi;

  echo "ABillS NAT ${ACTION}"

  if [[ x${ACTION} = xstatus ]]; then
    ${IPT} -t nat -L
    return 0;
  fi;

  ABILLS_IPS=`echo ${abills_nat}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;

  for ABILLS_IPS_NAT in ${ABILLS_IPS}; do
  # NAT External IP
  NAT_IPS=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $1 }'`;
  # Fake net
  FAKE_NET=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
  #NAT IF
  NAT_IF=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $3 }'`;
  echo  "NAT: $NAT_IPS | $FAKE_NET $NAT_IF"
  if [[ x${NAT_IPS} = x ]]; then
    NAT_IPS=all
  fi;
  # nat configuration

  for IP in ${NAT_IPS}; do

    if [[ w${ACTION} = wstart ]]; then
     for IP_NAT in ${FAKE_NET}; do
     if [[ ${IP} =~ - ]]; then
      ${IPT} -t nat -A POSTROUTING -s ${IP_NAT} -j SNAT --to-source ${IP} --persistent
      echo "Enable NAT for ${IP_NAT} > ${IP}"
     else
      ${IPT} -t nat -A POSTROUTING -s ${IP_NAT} -j SNAT --to-source ${IP}
      echo "Enable NAT for ${IP_NAT}"
     fi
     done;
    fi;
  done;
  done;
    if [[ x${ACTION} = xstop ]]; then
      ${IPT} -F -t nat
      ${IPT} -X -t nat
      echo "Disable NAT"
    fi;

}


#**********************************************************
#Neg deposit FWD Section
#**********************************************************
neg_deposit() {
  
  if [[ x"${abills_neg_deposit}" = x ]]; then
    return 0;
  fi;

  echo "NEG_DEPOSIT"

  if [[ "${abills_neg_deposit}" = "YES" ]]; then
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
abills_dhcp_shaper() {
  if [[ x${abills_dhcp_shaper} = xNO ]]; then
    return 0;
  elif [[ x${abills_dhcp_shaper} = x ]]; then
    return 0;
  fi;

  if [[ -f ${BILLING_DIR}/libexec/ipoe_shapper.pl ]]; then
    if [[ w${ACTION} = wstart ]]; then
      ${BILLING_DIR}/libexec/ipoe_shapper.pl -d ${NAS_IDS} IPN_SHAPPER
        echo " ${BILLING_DIR}/libexec/ipoe_shapper.pl -d ${NAS_IDS} IPN_SHAPPER";
    elif [[ w${ACTION} = wstop ]]; then
        if [[ -f ${BILLING_DIR}/var/log/ipoe_shapper.pid ]]; then
        IPOE_PID=`cat ${BILLING_DIR}/var/log/ipoe_shapper.pid`
        if  ps ax | grep -v grep | grep ipoe_shapper > /dev/null ; then
          echo "kill -9 ${IPOE_PID}"
          kill -9 ${IPOE_PID} ;
        fi;
        rm ${BILLING_DIR}/var/log/ipoe_shapper.pid
        else
        echo "Can\'t find 'ipoe_shapper.pid' "
        fi;
    fi;
  else
    echo "Can\'t find 'ipoe_shapper.pl' "
  fi;
}
#**********************************************************
#
#**********************************************************
check_server(){
  if [[ x${abills_mysql_server_status} = xNO ]]; then
    return 0;
  elif [[ x${abills_mysql_server_status} = x ]]; then
    return 0;
  fi;

if [[ w${ACTION} = wstart ]]; then
while : ; do

if ping -c5 -l5 -W2 ${abills_mysql_server} 2>&1 | grep "64 bytes from" > /dev/null ;
then echo "Abills Mysql server is UP!!!" ;
sleep 5;
return 0;
else echo "Abills Mysql server is DOWN!!!" ;
fi;
sleep 5
done
#}
fi;
}
#**********************************************************
#IRQ2SMP
#**********************************************************
irq2smp(){
  if [[ x${abills_irq2smp} = xNO ]]; then
    return 0;
  elif [[ x${abills_irq2smp} = x ]]; then
    return 0;
  fi;

if [[ w${ACTION} = wstart ]]; then
ncpus=`grep -ciw ^processor /proc/cpuinfo`
test "$ncpus" -gt 1 || exit 1

n=0
for irq in `cat /proc/interrupts | grep eth[0-9]- | awk '{print $1}' | sed s/\://g`
do
    f="/proc/irq/$irq/smp_affinity"
    test -r "$f" || continue
    cpu=$[$ncpus - ($n % $ncpus) - 1]
    if [[ ${cpu} -ge 0 ]]
            then
                mask=`printf %x $[2 ** $cpu]`
                echo "Assign SMP affinity: eth$n, irq $irq, cpu $cpu, mask 0x$mask"
                echo "$mask" > "$f"
                let n+=1
    fi
done
fi;
}
#**********************************************************
#IP Unnumbered
#**********************************************************
ip_unnumbered(){
  if [[ x${abills_unnumbered} = xNO ]]; then
    return 0;
  elif [[ x${abills_unnumbered} = x ]]; then
    return 0;
  fi;

if [[ w${ACTION} = wstart ]]; then
  sysctl -w net.ipv4.conf.default.proxy_arp=1
  if [[ x"${abills_unnumbered_net}" != x ]]; then
      UNNUNBERED_NETS=`echo ${abills_unnumbered_net}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
      for UNNUNBERED_NET in ${UNNUNBERED_NETS}; do
         /sbin/ip ro replace unreachable ${UNNUNBERED_NET}
         echo "Add route unreachable $UNNUNBERED_NET"
      done
      UNNUNBERED_GW=`echo ${abills_unnumbered_gw}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
      for GW in ${UNNUNBERED_GW}; do
        /sbin/ip addr add ${GW} dev lo
        echo "Add  $GW dev lo"
      done

      if [[ x"${abills_unnumbered_iface}" != x ]]; then
        UNNUNBERED_INTERFACES="";
        unnumbered_ifaces=`echo ${abills_unnumbered_iface} | sed 'N;s/\n/ /' |sed 's/,/ /g'`
        for i in ${unnumbered_ifaces}; do
          if [[ ${i} =~ - ]]; then
             vlan_name=`echo ${i}|sed 's/vlan//'`
             IFS='-' read -a start_stop <<< "$vlan_name"
             for cur_iface in `seq ${start_stop[0]} ${start_stop[1]}`;
             do
                  UNNUNBERED_INTERFACES="$UNNUNBERED_INTERFACES vlan${cur_iface}"
             done
          else
              UNNUNBERED_INTERFACES="$UNNUNBERED_INTERFACES $i"
          fi;
        done
        if [[ x"${abills_unnumbered_gw}" != x ]]; then
          UNNUNBERED_GW=`echo ${abills_unnumbered_gw}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
          for UNNUNBERED_INTERFACE in ${UNNUNBERED_INTERFACES}; do
               for GW in ${UNNUNBERED_GW}; do
                 /sbin/ip addr add ${GW} dev ${UNNUNBERED_INTERFACE}
                 sysctl -w net.ipv4.conf.${UNNUNBERED_INTERFACE}.proxy_arp=1
#              sysctl -w net.ipv4.conf.$UNNUNBERED_INTERFACE.proxy_arp_pvlan=0
                echo "Add  $GW dev $UNNUNBERED_INTERFACE"
              
              done
          done
        else
          echo "unknown IP Unnumbered GATEWAY"
        fi;

      else
        echo "unknown IP Unnumbered IFACE"
      fi;

  else
   echo "unknown IP Unnumbered NET"
  fi;

fi;
if [[ w${ACTION} = wstop ]]; then
  /sbin/ip route flush type  unreachable
  DEVACES_ADDR=`/sbin/ip addr show |grep /32 |awk '/inet/{print $2,$5}'|sed 's/ /:/g' |sed 'N;s/\n/ /'`
  for DEV_ADDR in ${DEVACES_ADDR}; do
    IP=`echo ${DEV_ADDR} |awk -F: '{print $1}'`
    DEV=`echo ${DEV_ADDR} |awk -F: '{print $2}'`
#   if [[ $DEV == "lo" ]]; then
    /sbin/ip addr del ${IP} dev ${DEV}
#    /sbin/ip route flush dev $DEV
    echo "DELETE $IP for dev $DEV"
#  fi
  done
fi;

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
    *) echo "Usage: shapper_start.sh
 start|stop|status|restart|clear"
    exit 1
    ;; 
    esac 


exit 0
