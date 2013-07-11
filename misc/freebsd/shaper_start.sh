#!/bin/sh
# Shaper/NAT/Session upper for ABillS 
#
# PROVIDE: abills_shaper
# REQUIRE: NETWORKING mysql vlan_up 

. /etc/rc.subr

# Add the following lines to /etc/rc.conf to enable abills_shapper:
#
#   abills_shaper_enable="YES" - Enable abills shapper
#
#   abills_shaper_if="" - ABillS shapper interface default ng*
#
#   abills_nas_id="" - ABillS NAS ID default 1
#
#   abills_ip_sessions="" - ABIllS IP SEssions limit
#
#   abills_nat="EXTERNAL_IP:INTERNAL_IPS:NAT_IF;..." - Enable abills nat
#
#   abills_dhcp_shaper=""  (bool) :  Set to "NO" by default.
#                                    Enable ipoe_shaper
#
#   abills_dhcp_shaper_nas_ids="" : Set nas ids for shapper, Default: all nas servers
#
#   abills_mikrotik_shaper=""  :  NAS IDS
#                                    
#IPN Section configuration
#
#   abills_ipn_nas_id="" ABillS IPN NAS ids, Enable IPN firewall functions
#
#   abills_ipn_if="" IPN Shapper interface
#
#   abills_ipn_allow_ip="" IPN Allow unauth ip
#
#Other
#
#   abills_squid_redirect="" Redirect traffic to squid
#
#   abills_neg_deposit="" Enable neg deposit redirect
#
#   abills_neg_deposit_speed="512" Set default speed for negative deposit
#


CLASSES_NUMS='2 3'
VERSION=5.99


name="abills_shaper"

if [ x${abills_shaper_enable} = x ]; then
  name="abills_nat"
  abills_nat_enable=YES;
fi;

rcvar=`set_rcvar`




: ${abills_shaper_enable="NO"}
: ${abills_shaper_if=""}
: ${abills_nas_id=""}
: ${abills_ip_sessions=""}
: ${abills_nat=""}
: ${abills_dhcp_shaper="NO"}
: ${abills_dhcp_shaper_nas_ids=""}
: ${abills_neg_deposit="NO"}
: ${abills_neg_deposit_speed=""}
: ${abills_portal_ip="me"}
: ${abills_mikrotik_shaper=""}
: ${abills_squid_redirect="NO"}

: ${abills_ipn_nas_id=""}
: ${abills_ipn_if=""}
: ${abills_ipn_allow_ip=""}



load_rc_config $name
#run_rc_command "$1"

IPFW=/sbin/ipfw
SED=/usr/bin/sed
BILLING_DIR=/usr/abills

start_cmd="abills_shaper_start"
stop_cmd="abills_shaper_stop"
restart_cmd="abills_shaper_restart"

if [ x${abills_mikrotik_shaper} != x ]; then
  ${BILLING_DIR}/libexec/billd checkspeed mikrotik NAS_IDS="${abills_mikrotik_shaper}" RECONFIGURE=1
fi;

#Negative deposit forward (default: )
FWD_WEB_SERVER_IP=127.0.0.1;
#Your user portal IP (Default: me)
USER_PORTAL_IP=${abills_portal_ip}

#ACTION=$1
#echo -n ${ACTION}
#if [ w${ACTION} = wfaststart ]; then
#  ACTION=start
#fi;

#make at ipfw -q flush
if [ w${ACTION} = wtest ]; then
  ACTION=start
  echo "${IPFW} -q flush" | at +10 minutes
fi;

EXTERNAL_INTERFACE=`/sbin/route get default | grep interface: | awk '{ print $2 }'`
  
#Get external interface
if [ x${abills_shaper_if} != x ]; then
  INTERNAL_INTERFACE=${abills_shaper_if}
else 
  INTERNAL_INTERFACE=ng\*
fi; 

#**********************************************************
#
#**********************************************************
abills_shaper_start() {
  ACTION=start

abills_shaper
abills_dhcp_shaper
abills_ipn
abills_nat
external_fw_rules
neg_deposit
abills_ip_sessions
squid_redirect
}

#**********************************************************
#
#**********************************************************
abills_shaper_stop() {
  ACTION=stop

abills_shaper
abills_dhcp_shaper
abills_ipn
abills_nat
neg_deposit
abills_ip_sessions
squid_redirect
}

#**********************************************************
#
#**********************************************************
abills_shaper_restart() {
  abills_shaper_stop
  abills_shaper_start
}

#**********************************************************
# Abills Shapper
#**********************************************************
abills_shaper() {
  if [ x${abills_shaper_enable} = xNO ]; then
    return 0;
  elif [ x${abills_shaper_enable} = xNAT ]; then
    return 0;
  fi;
  
  echo "ABillS Shapper ${ACTION}"
  
  #Octets direction
  PKG_DIRECTION=`cat ${BILLING_DIR}/libexec/config.pl | grep octets_direction | ${SED} "s/\\$conf{octets_direction}='\(.*\)'.*/\1/"`

  if [ w${PKG_DIRECTION} = wuser ] ; then
    IN_DIRECTION="in recv ${INTERNAL_INTERFACE}"
    OUT_DIRECTION="out xmit ${INTERNAL_INTERFACE}"
  else
    IN_DIRECTION="out xmit ${EXTERNAL_INTERFACE}"
    OUT_DIRECTION="in recv ${EXTERNAL_INTERFACE}"
  fi; 

  #Enable NG shapper
  if [ w != w`grep '^\$conf{ng_car}=1;' ${BILLING_DIR}/libexec/config.pl` ]; then
    NG_SHAPPER=1
  fi;

  #Main users table num
  USERS_TABLE_NUM=10
  #First Class traffic users
  USER_CLASS_TRAFFIC_NUM=10

  #NG Shaper enable
  if [ w${ACTION} = wstart -a w${NG_SHAPPER} != w ]; then
    echo -n "ng_car shapper"
    #Load kernel modules
    kldload ng_ether
    kldload ng_car
    kldload ng_ipfw

    for num in ${CLASSES_NUMS}; do
      #  FW_NUM=`expr  `;
      echo "Traffic: ${num} "
      #Shaped traffic
      ${IPFW} add ` expr 10000 - ${num} \* 10 ` skipto ` expr 10100 + ${num} \* 10 ` ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to table\(${num}\) ${IN_DIRECTION}
      ${IPFW} add ` expr 10000 - ${num} \* 10 + 5 ` skipto ` expr 10100 + ${num} \* 10 + 5 ` ip from table\(${num}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}

      ${IPFW} add ` expr 10100 + ${num} \* 10 ` netgraph tablearg ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to any ${IN_DIRECTION}
      ${IPFW} add ` expr 10100 + ${num} \* 10 + 5 ` netgraph tablearg ip from any to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}

     #Unlim traffic
     ${IPFW} add ` expr 10200 + ${num} \* 10 ` allow ip from table\(9\) to table\(${num}\) ${IN_DIRECTION}
     ${IPFW} add ` expr 10200 + ${num} \* 10 + 5 ` allow ip from table\(${num}\) to table\(9\) ${OUT_DIRECTION}
    done;

    echo "Global shaper"
    ${IPFW} add 10000 netgraph tablearg ip from table\(10\) to any ${IN_DIRECTION}
    ${IPFW} add 10010 netgraph tablearg ip from any to table\(11\) ${OUT_DIRECTION}
    ${IPFW} add 10020 allow ip from table\(9\) to any ${IN_DIRECTION}
    ${IPFW} add 10025 allow ip from any to table\(9\) ${OUT_DIRECTION}
    if [ ${INTERNAL_INTERFACE} = w"ng*" ]; then
      ${IPFW} add 10030 allow ip from any to any via ${INTERNAL_INTERFACE} 
    fi;
  #done
  #Stop ng_car shaper
  elif [ w${ACTION} = wstop -a w$2 = w ]; then
    echo "Stop shapper" 

    for num in ${CLASSES_NUMS}; do
      ${IPFW} delete ` expr 9100 + ${num} \* 10 + 5 ` ` expr 9100 + ${num} \* 10 `  ` expr 9000 + ${num} \* 10 ` ` expr 10000 - ${num} \* 10 ` ` expr 10100 + ${num} \* 10 ` ` expr 10200 + ${num} \* 10 ` ` expr 9000 + ${num} \* 10 + 5 ` ` expr 10000 - ${num} \* 10 + 5 ` ` expr 10100 + ${num} \* 10 + 5 ` ` expr 10200 + ${num} \* 10 + 5 ` 
    done;

    ${IPFW} delete 9000 9005 10000 10010 10015 08000 08010  09010 10020 10025
  else   
    echo "DUMMYNET shaper"
    if [ w${abills_nas_id} = w ]; then
      abills_nas_id=1;
    fi;

    ${BILLING_DIR}/libexec/billd checkspeed NAS_IDS=${abills_nas_id} RECONFIGURE=1 FW_DIRECTION_OUT="${OUT_DIRECTION}" FW_DIRECTION_IN="${IN_DIRECTION}";
  fi;
}


#**********************************************************
#IPoE Shapper for dhcp connections
#**********************************************************
abills_dhcp_shaper() {
  if [ ${abills_dhcp_shaper} = NO ]; then
    return 0;
  fi;

  if [ -f ${BILLING_DIR}/libexec/ipoe_shapper.pl ]; then
    if [ x${abills_dhcp_shaper_nas_ids} != x ]; then
      NAS_IDS="NAS_IDS=${abills_dhcp_shaper_nas_ids}"
    fi;
    if [ w${ACTION} = wstart ]; then
      ${BILLING_DIR}/libexec/ipoe_shapper.pl -d ${NAS_IDS}
    elif [ w${ACTION} = wstop ]; then
      kill `cat ${BILLING_DIR}/var/log/ipoe_shapper.pid`
    fi;
  else
    echo "Can\'t find 'ipoe_shapper.pl' "
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
  if [ w${ACTION} = wstart ]; then
  	if [ x${abills_ipn_if} != x ]; then
    		IFACE=" via ${abills_ipn_if}"
  	fi;

  	#Redirect unauth ips to portal
  	${IPFW} add 64000 fwd 127.0.0.1,80 tcp from any to any dst-port 80 ${IFACE} in

  	# Разрешить ping к серверу доступа
  	${IPFW} add 64100 allow icmp from any to me  ${IFACE}
  	${IPFW} add 64101 allow icmp from me to any  ${IFACE}

    if [ x${abills_ipn_allow_ip} != x ]; then
    	# Доступ к странице авторизации  
    	${IPFW} add 10 allow tcp from any to ${abills_ipn_allow_ip} 9443  ${IFACE}
    	${IPFW} add 11 allow tcp from ${abills_ipn_allow_ip} 9443 to any  ${IFACE}
    	${IPFW} add 12 allow tcp from any to ${abills_ipn_allow_ip} 80  ${IFACE}
    	${IPFW} add 13 allow tcp from ${abills_ipn_allow_ip} 80 to any  ${IFACE}
  
    	# Разрешить ДНС запросы к серверу
    	${IPFW} add 64400 allow udp from any to ${abills_ipn_allow_ip} 53
    	${IPFW} add 64450 allow udp from ${abills_ipn_allow_ip} 53 to any
    fi;
  
  	echo "Restart active sessions"
  	/usr/abills/libexec/periodic monthly MODULES=Ipn SRESTART=1 NO_ADM_REPORT=1 NAS_IDS="${abills_ipn_nas_id}" &
  	# Block unauth ips
  	#${IPFW} add 65000 deny ip from not table\(10\) to any ${IFACE} in
  	${IPFW} add 65000 deny ip from any to any ${IFACE} in
  elif [ w${ACTION} = wstop ]; then
	  ${IPFW} delete 10 11 12 13 64000 64100 64101  64400 64450 65000
  fi;		
}

#**********************************************************
# Start custom shapper rules
#**********************************************************
external_fw_rules() {
  if [ ${firewall_type} = "/etc/fw.conf" ]; then
	cat ${firewall_type} | while read line
	do
	 RULEADD=`echo ${line} | awk '{print \$1}'`;    	
         NUMBERIPFW=`echo ${line} | awk '{print \$2}'`;
	if [ w${RULEADD} = wadd ]; then
         	NOEX=`${IPFW} show  ${NUMBERIPFW} 2>/dev/null | wc -l`;
    		if [ ${NOEX} -eq 0 ]; then
			${IPFW} ${line};		
		fi;
	fi;	
	done;
  fi;
}

#**********************************************************
#NAT Section
# options IPFIREWALL_FORWARD
# options IPFIREWALL_NAT
# options LIBALIAS
#Nat Section
#**********************************************************
abills_nat() {
if [ x"${abills_nat}" = x ]; then
return 0;
fi;
echo "ABillS NAT ${ACTION}"
abills_ips_nat=`echo ${abills_nat} | sed 's/ //g'`;
abills_ips_nat=`echo ${abills_nat} | sed 's/;/ /g'`;


NAT_TABLE=20
NAT_FIRST_RULE=20
NAT_USERS_RULE=21
NAT_REAL_TO_FAKE_TABLE_NUM=33;

for IPS_NAT in ${abills_ips_nat}; do
# NAT External IP
NAT_IPS=`echo ${IPS_NAT} | awk -F: '{ print $1 }'`;
# Fake net
FAKE_NET=`echo ${IPS_NAT} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
#NAT IF
NAT_IF=`echo ${IPS_NAT} | awk -F: '{ print $3 }'`;

echo " NAT ${ACTION}"

# nat configuration
for IP in ${NAT_IPS}; do
if [ w${ACTION} = wstart ]; then

${IPFW} nat ${NAT_USERS_RULE} config ip ${IP} log
${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} add ${IP} ${NAT_USERS_RULE}


for f_net in ${FAKE_NET}; do
${IPFW} table ` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1` add ${f_net} ${NAT_USERS_RULE}
done;


else if [ w${ACTION} = wstop ]; then
${IPFW} nat delete ${NAT_USERS_RULE}
fi;
fi;
done;

NAT_USERS_RULE=` expr ${NAT_USERS_RULE} + 1`
done;



# UP NAT
if [ w${ACTION} = wstart ]; then
if [ w${NAT_IF} != w ]; then
NAT_IF="via ${NAT_IF}"
fi;

${IPFW} add 60010 nat tablearg ip from table\(` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1 `\) to any $NAT_IF
${IPFW} add 20 nat tablearg ip from any to table\(${NAT_REAL_TO_FAKE_TABLE_NUM}\) $NAT_IF

else if [ w${ACTION} = wstop ]; then
${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} flush
${IPFW} table ` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1 ` flush
${IPFW} delete 60010 20 60015

fi;
fi;
}


#**********************************************************
#Neg deposit FWD Section
#**********************************************************
neg_deposit() {

  if [ "${abills_neg_deposit}" = NO ]; then
    return 0;
  fi;

  echo "Negative Deposit Forward Section ${ACTION}"
  if [ w${WEB_SERVER_IP} = w ]; then
    FWD_WEB_SERVER_IP=127.0.0.1;
  fi;
  
  if [ w${DNS_IP} = w ]; then
    DNS_IP=`cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }' | head -1`
  fi;

  FWD_RULE=10014;

  #Forwarding start
  if [ x${ACTION} = xstart ]; then
    ${IPFW} add ${FWD_RULE} fwd ${FWD_WEB_SERVER_IP},80 tcp from table\(32\) to any dst-port 80,443 via ${INTERNAL_INTERFACE}
    #If use proxy
    #${IPFW} add ${FWD_RULE} fwd ${FWD_WEB_SERVER_IP},3128 tcp from table\(32\) to any dst-port 3128 via ${INTERNAL_INTERFACE}
    # if allow usin net on neg deposit
    if [ x${abills_neg_deposit_speed} != x ]; then
      ${IPFW} add 9000 skipto ${FWD_RULE} ip from table\(32\) to any ${IN_DIRECTION}
      ${IPFW} add 9001 skipto ${FWD_RULE} ip from any to table\(32\) ${OUT_DIRECTION}

      #${IPFW} add 10020 pipe 1${abills_neg_deposit_speed} ip from any to not table\(10\) ${IN_DIRECTION}
      #${IPFW} add 10021 pipe 1${abills_neg_deposit_speed} ip from not table\(10\) to any ${OUT_DIRECTION}
      #${IPFW} pipe 1${abills_neg_deposit_speed} config bw ${abills_neg_deposit_speed}Kbit/s mask src-ip 0xfffffffff    
    
      ${IPFW} add `expr ${FWD_RULE} + 30` pipe 1${abills_neg_deposit_speed} ip from any to not table\(10\) ${IN_DIRECTION}
      ${IPFW} add `expr ${FWD_RULE} + 31` pipe 1${abills_neg_deposit_speed} ip from not table\(10\) to any ${OUT_DIRECTION}
      ${IPFW} pipe 1${abills_neg_deposit_speed} config bw ${abills_neg_deposit_speed}Kbit/s mask src-ip 0xfffffffff
    else    
      ${IPFW} add `expr ${FWD_RULE} + 10` allow ip from table\(32\) to ${DNS_IP} dst-port 53 via ${INTERNAL_INTERFACE}
      ${IPFW} add `expr ${FWD_RULE} + 20` allow tcp from table\(32\) to ${USER_PORTAL_IP} dst-port 9443 via ${INTERNAL_INTERFACE}
      ${IPFW} add `expr ${FWD_RULE} + 30` deny ip from table\(32\) to any via ${INTERNAL_INTERFACE}
    fi;
  elif [ w${ACTION} = wstop ]; then
    ${IPFW} delete ${FWD_RULE} ` expr ${FWD_RULE} + 10 ` ` expr ${FWD_RULE} + 20 ` ` expr ${FWD_RULE} + 30 `
  elif [ w${ACTION} = wshow ]; then
    ${IPFW} show ${FWD_RULE}
  fi;
}

#**********************************************************
#Session limit section
#**********************************************************
abills_ip_sessions() {

if [ x${abills_ip_sessions} = x ]; then
  return 0;
fi;

  echo "Session limit ${abills_ip_sessions}";
  if [ w${ACTION} = wstart ]; then
    ${IPFW} add 00400   skipto 65010 tcp from table\(34\) to any dst-port 80,443 via ${INTERNAL_INTERFACE}
    ${IPFW} add 00401   skipto 65010 udp from table\(34\) to any dst-port 53 via ${INTERNAL_INTERFACE}
    ${IPFW} add 00402   skipto 60010 tcp from table\(34\) to any via ${EXTERNAL_INTERFACE}
    ${IPFW} add 64001   allow tcp from table\(34\) to any setup via ${INTERNAL_INTERFACE} in limit src-addr ${abills_ip_sessions}
    ${IPFW} add 64002   allow udp from table\(34\) to any via ${INTERNAL_INTERFACE} in limit src-addr ${abills_ip_sessions}
    ${IPFW} add 64003   allow icmp from table\(34\) to any via ${INTERNAL_INTERFACE} in limit src-addr ${abills_ip_sessions}
  elif [ w${ACTION} = wstop ]; then
    ${IPFW} delete 00400 00401 00402 64001 64002 64003
  fi;
}

#**********************************************************
#Squid Redirect
#**********************************************************
squid_redirect() {
#FWD Section
if [ ${abills_squid_redirect} = NO ]; then
  return 0;
fi;

  if [ x${SQUID_SERVER_IP} = w ]; then
    SQUID_SERVER_IP=127.0.0.1;
  fi;
  
  SQUID_REDIRET_TABLE=40
  FWD_RULE=10040;

  #Forwarding start
  if [ w${ACTION} = wstart ]; then
    echo "Squid Forward Section - start"; 
    ${IPFW} add ${FWD_RULE} fwd ${SQUID_SERVER_IP},8080 tcp from table\(${SQUID_REDIRET_TABLE}\) to any dst-port 80,443 via ${INTERNAL_INTERFACE}
    #If use proxy
    #${IPFW} add ${FWD_RULE} fwd ${FWD_WEB_SERVER_IP},3128 tcp from table\(32\) to any dst-port 3128 via ${INTERNAL_INTERFACE}
  elif [ x${ACTION} = xstop ]; then
    echo "Squid Forward Section - stop:"; 
    ${IPFW} delete ${FWD_RULE}
  elif [ x${ACTION} = xshow ]; then
    echo "Squid Forward Section - status:"; 
    ${IPFW} show ${FWD_RULE}
  fi; 
}



load_rc_config $name
run_rc_command "$1"

