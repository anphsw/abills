#!/bin/sh

# PROVIDE: vlan_up
# REQUIRE: NETWORKING mysql
# BEFORE: mpd
# KEYWORD: shutdown

# abills_vlan_nas - abills local vlan nas id
#
# Precreated vlans for speed up system
#
# abills_vlan_if         - interface
#
# abills_vlan_precreated - count
#
# abills_vlan_gw         - vlan gateway
#


. /etc/rc.subr

name="abills_vlan_up"
rcvar=`set_rcvar`

load_rc_config $name

: ${abills_vlan_precreated=0}
n=${abills_vlan_precreated}
parent_if=${abills_vlan_if}
gw_ip=${abills_vlan_gw}


if [ ${n} -lt 0 ]; then
  /usr/sbin/route delete ${gw_ip}
  while [ $n -lt 250 ] ;  do
    n=`expr $n + 1`;
    echo -n "vlan$n,";
    /sbin/ifconfig vlan$n create vlan $n vlandev ${parent_if}  up;
  #   /sbin/ifconfig ${parent_if}.$n create up;
  #    /sbin/ifconfig ${parent_if}.$n create 213.110.45.1/32 up;
  #    /sbin/route add -net 213.110.45.`expr $n + 1`/32 -cloning -iface em1.$n
  done;
fi;


echo "VLAN NAS: ${abills_vlan_nas}"

/usr/abills/libexec/periodic daily MODULES=Vlan LOCAL_NAS_IDS=${abills_vlan_nas}
