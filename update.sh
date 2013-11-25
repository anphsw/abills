#!/bin/sh
# AbillS CVS update
# Amon update
#
#***********************************************



VERSION=1.03;

#ABillS Rel Version
REL_VERSION="rel-0-5";

BILLING_DIR='/usr/abills';
FIND='/usr/bin/find';
SED=`which sed`;
DATE=`date "+%Y%m%d"`;
FULL_DATE=`date`;
TMP_DIR=/tmp
MYSQL=mysql
OS=`uname`;
echo "OS: ${OS}"

UPDATE_LOGIN=
UPDATE_PASSWD=
UPDATE_CHECKSUM=
SNAPHOT_URL=http://abills.net.ua/snapshots/

if [ w${OS} = wLinux ]; then
  FETCH="wget -q -O"
  MD5="md5sum"
else 
  FETCH="fetch -q -o"
  MD5="md5"
fi;


#**********************************************************
# Get OS
#**********************************************************
get_os () {
OS=`uname -s`
OS_VERSION=`uname -r`
MACH=`uname -m`
if [ "${OS}" = "SunOS" ] ; then
	OS=Solaris
	ARCH=`uname -p`	
	OSSTR="${OS} ${OS_VERSION}(${ARCH} `uname -v`)"
elif [ "${OS}" = "AIX" ] ; then
	OSSTR="${OS} `oslevel` (`oslevel -r`)"
elif [ "${OS}" = "Linux" ] ; then
  #GetVersionFromFile
	KERNEL=`uname -r`
	if [ -f /etc/redhat-release ] ; then
		OS_NAME='RedHat'
		PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
		OS_VERSION=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
	elif [ -f /etc/SuSE-release ] ; then
		OS_NAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
		OS_VERSION=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
	elif [ -f /etc/mandrake-release ] ; then
		OS_NAME='Mandrake'
		PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
		OS_VERSION=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
	elif [ -f /etc/debian_version ] ; then
		OS_NAME="Debian";
		OS_NAME=`cat /etc/debian_version`;
		#OS_VERSION=`cat /etc/issue | head -1 |awk '{ print $3 }'`
  elif [ -f /etc/slackware-version ]; then 
    OS_NAME=`cat /etc/slackware-version | awk '{ print $1 }'`
    OS_VERSION=`cat /etc/slackware-version | awk '{ print $2 }'` 	
	fi

	if [ -f /etc/UnitedLinux-release ] ; then
		OS_NAME="${OS_NAME}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
	fi
	
	#OSSTR="${OS} ${OS_NAME} ${OS_VERSION}(${PSUEDONAME} ${KERNEL} ${MACH})"
fi
}

#**********************************************
# Sysinfo
#
#**********************************************
sys_info  () {

get_os

if [ x${OS} = xFreeBSD ]; then
  CPU=`grep -i CPU: /var/run/dmesg.boot | cut -d \: -f2 | tail -1`

  if [ "${CPU}" = "" ]; then
    CPU=`sysctl -a | egrep -i 'hw.machine|hw.model|hw.ncpu'`
    CPU=`sysctl hw.model | sed "s/hw.model: //g"`;
  fi;

  VGA_device=`pciconf -lv |grep -B 3 VGA |grep device |awk -F "'" '{print $2}' |paste -s -`
  VGA_vendor=`pciconf -lv |grep -B 3 VGA |grep vendor |awk -F "'" '{print $2}' |paste -s -`

  ntf=`grep -i Network /var/run/dmesg.boot |cut -d \: -f1`
  RAM=`grep -i "real memory" /var/run/dmesg.boot | sed 's/.*(\([0-9]*\) MB)/\1/' | tail -1`
  if [ "${RAM}" = "" ]; then
    RAM=`sysctl hw.physmem | awk '{ print \$2 "/ 1048576" }' | bc`;
  fi;

  HDD=`grep -i ^ad[0-9]: /var/run/dmesg.boot | tail -1`
  if [ "${HDD}" = "" ]; then
    HDD=`grep -i ^ada[0-9]: /var/run/dmesg.boot | tail -1`
  fi;
  
  hdd_model=${HDD}
  hdd_serial=`echo ${HDD} | sed 's/.*<\(.*\)>.*/\1/g'`
  hdd_size=`echo ${HDD} | awk '{ print $2 }'`

  Version=`uname -r`
  INTERFACES=`ifconfig | grep "[a-z0-9]: f" | awk '{ print $1 }' | grep -v -E "ng*|vlan*|lo*|ppp*|ipfw*"`;

  #interface () {
  #  for eth in $(grep -i Network /var/run/dmesg.boot |cut -d \: -f1 |paste -s -); do
  #    eth1=`grep -i Network /var/run/dmesg.boot |grep $eth |awk -F "<" '{print $2}'|awk -F ">" '{print $1}'`
  #    eth2=`pciconf -lv |grep -A 2 $eth |grep -v $eth |awk -F "\'" \'{print $2}\' |paste -s -`
  # 
  #    INTERFACES="$eth on $eth1
  #                      $eth2"
  #  done;
  #}
elif [ x${OS} = xLinux ]; then
   #CPU=`grep -i  "MHz proc" /var/log/dmesg |awk '{print $2, $3}'`
   CPU=`cat /proc/cpuinfo |egrep '(model name|cpu MHz)' | sed 's/.*\: //'|paste -s`
   INTERFACES=`lspci -mm |grep Ethernet |cut -f4- -d " "`
   RAM=`free -mo |grep Mem |awk '{print $2}'`
   VGA=`lspci |grep VGA |cut -f5- -d " "`
   hdd_size=`fdisk -l |head -2 |tail -1|awk '{print $3,$4}'|sed 's/,//'`
   hdd_system_name=`fdisk -l | head -2 | tail -1 |awk '{ print $2 }' | sed 's/://'`
   if [ ! -f '/sbin/hdparm' ]; then
     if [ "${OS_NAME}" = 'Debian' ]; then
       apt-get install hdparm
     elif [ "${OS_NAME}" = 'Ubuntu' ]; then
       apt-get install hdparm
     fi;
   fi;

   hdd_model=`hdparm -I ${hdd_system_name} |grep Model |awk -F ":" '{print $2}' |tr -cs -`
   hdd_serial=`hdparm -I ${hdd_system_name} |grep Serial |awk -F ":" '{print $2}' |tr -cs -`
fi;

sys_info="${CPU}^${RAM}^${VGA}^${hdd_model}^${hdd_serial}^${hdd_size}^${OS}^${OS_VERSION}^${OS_NAME}${INTERFACES}"
CHECKSUM=`echo "${sys_info}" | ${MD5} | awk '{print $1 }'`

if [ x"${REGISTRATION}" != x ]; then
  echo "Please enter login password for server registration"
  echo -n "Login: "
  read LOGIN
  echo -n "Password: "
  read PASSWORD
  HOSTNAME=`hostname`
  ${FETCH} ${TMP_DIR}/update.sh "${UPDATE_URL}?""sys_info=${sys_info}&SIGN=${CHECKSUM}&L=${LOGIN}&P=${PASSWORD}&H=${HOSTNAME}";
  VAR=`cat ${TMP_DIR}/update.sh;`
  
  echo ${VAR};
  rm ~/.updater
  RESULT=`echo "${VAR}" | grep comple`;
  if [ x"${RESULT}" != x ]; then
    REGISTRATION=""
    echo ${SIGN} > ~/.updater
  else
    echo "Registration failed"
    exit;
  fi;
  
  return 0;
fi;


SYSTEM_INFO="System information
  CPU    -    ${CPU} MHz
  RAM    -    ${RAM} Mb
  VGA    -    ${VGA}
              manufacture: ${VGA_vendor}
              model: ${VGA_device}

  HDD    -    Model:  ${hdd_model} 
              Serial: ${hdd_serial} 
              Size:   ${hdd_size}
  INTERFACES   - ${INTERFACES}
  OS           - ${OS}
  Version      - ${OS_VERSION}
  Distributive - ${OS_NAME}
  CHECKSUM     - ${CHECKSUM}
"
if [ x${SYS_INFO} != x ] ; then
  echo "${SYSTEM_INFO}"
fi;

UPDATE_CHECKSUM=${CHECKSUM}
}



#**********************************************
# Update SQL Section
#
#**********************************************
update_self () {
  UPDATE_URL="http://abills.net.ua/misc/update.sh"
  UPDATE_URL="http://abills.net.ua/misc/update.php"
  
  sys_info
  SIGN=${UPDATE_CHECKSUM}
  echo "Verifing please wait..."
  
if [ -f ~/.updater ]; then
  SIGN=`cat ~/.updater`
else
  echo ${SIGN} > ~/.updater
  chmod 400 ~/.updater
  SIGN=${SIGN}"&hn="`hostname`;
fi;


${FETCH} ${TMP_DIR}/update.sh "${UPDATE_URL}?sign=${SIGN}&getupdate=1";

if [ -f "${TMP_DIR}/update.sh" ]; then
  RESULT=`grep "^ERROR:" ${TMP_DIR}/update.sh`;

  if [ x"${RESULT}" != x ] ; then
    echo "${RESULT}";
    echo "Please Registration:"
    REGISTRATION=1;
    sys_info;    
  else
    NEW=`cat ${TMP_DIR}/update.sh |grep "^VERSION=" | sed  "s/VERSION=\(.*\);/\1/"`;
    VERSION_NEW=0
    if [ x${NEW} != x ]; then
      VERSION_NEW=`echo "${NEW} * 100" |bc |cut -f1 -d "."`;
    fi;

    VERSION_OLD=`echo "${VERSION} * 100" | bc |cut -f1 -d "."`;

    if [ ${VERSION_OLD} -lt ${VERSION_NEW} ] > /dev/null 2>&1; then
      echo " "
      echo -n "!!! New version '${NEW}' of update.sh availeble update it [Y/n]: "
    
      read update_confirm
  
      if [ w${update_confirm} = wy ]; then
        CUR_FILE=`pwd`"/update.sh"
        cp ${TMP_DIR}/update.sh ${CUR_FILE}
        echo "update.sh updated. Please restart program";
        exit;
      fi;   
    fi;

  fi;
fi;

}


#**********************************************
# Update SQL Section
#
#**********************************************
update_sql () {
  
  if [ ! -f ${BILLING_DIR}/libexec/config.pl ]; then
    return 0;
  fi;
  
DB_USER=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbuser}' |awk -F"'" '{print $2}'`
DB_PASSWD=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbpasswd}' |awk -F"'" '{print $2}'`
DB_NAME=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbname}' |awk -F"'" '{print $2}'`
DB_HOST=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbhost}' |awk -F"'" '{print $2}'`
DB_CHARSET=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbcharset}' |awk -F"'" '{print $2}'`

if [ "${SKIP_CHECK_SQL}" != 1 ]; then
  #Check MySQL Version
  MYSQL_VERSION=`${MYSQL} -u ${DB_USER} -p${DB_PASSWD} -h ${DB_HOST} -D ${DB_NAME} -e "SELECT version()"`
  echo "MySQL: Version: ${MYSQL_VERSION}"
  MYSQL_VERSION=`echo ${MYSQL_VERSION} | sed 's/.*\([0-9]\)\.\([0-9]*\)\.\([0-9]*\).*/\1\2/'`;
  
  if [ "${MYSQL_VERSION}" -lt 56 ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "! Please Update Mysql Server to version 5.6 or higher                        !"
    echo "! More information http://abills.net.ua/forum/viewtopic.php?f=1&t=6951       !"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit;
  fi;

fi;

if [ -f ${BILLING_DIR}/libexec/config.pl ]; then
  UPDATEDATE=`cat ${BILLING_DIR}/libexec/config.pl |grep version |cut -f2 -d"/" |cut -f1 -d"'"`
else
  UPDATEDATE=0
fi;

if  [ "$UPDATEDATE" = '$conf{version}='  ]; then
  UPDATEDATE=99999999
fi;

if [ "${UPDATEDATE}" -lt 99999999 ]; then
  echo "Updating SQL"

  CHANGELOG_URL="http://abills.net.ua/wiki/doku.php?id=abills:changelogs:0.5x&do=export_raw"

  if [ w${OS} = wLinux ]; then
    wget -q -O ${TMP_DIR}/changes "${CHANGELOG_URL}";
  else
    fetch -q -o ${TMP_DIR}/changes "${CHANGELOG_URL}";
  fi;

  cat ${TMP_DIR}/changes |sed -n '/^[0-9]/p' |sed 's/\\\\//' |sed 's/\([0-9]*\).\([0-9]*\).\([0-9]*\)/\3\2\1/' >${TMP_DIR}/dates;

  for data in $(cat ${TMP_DIR}/dates); do
    if [ ${UPDATEDATE} -le $data ]; then
      #echo There is chenges for $data
      sed -e 's/\\\\//;s/\([0-9]*\).\([0-9]*\).\([0-9]*\)/\3\2\1/;/^*/d;/^SQL/d;/^$/d' ${TMP_DIR}/changes > ${TMP_DIR}/che
      echo `sed -n '/'"$data"'/,/^[0-9]/p' ${TMP_DIR}/che |sed -e '$d;1d;/^=/d'` >> ${TMP_DIR}/changes.sql
      cat ${TMP_DIR}/changes.sql |tr ';' '\n' | sed -e '/^$/d;s/$/;/;s/^ //;s/`/\\`/g' > ${TMP_DIR}/che;
   fi;
  done

  if [ x${DB_CHARSET} != x ]; then
    DB_CHARSET="--default-character-set=${DB_CHARSET}"
  fi;

  if [ -f "${TMP_DIR}/che" ]; then
    while IFS=';' read line ; do
      ${MYSQL} -u ${DB_USER} -p${DB_PASSWD} -h ${DB_HOST} ${DB_CHARSET} -D ${DB_NAME} -Bse "$line"
    done < ${TMP_DIR}/che
  fi;

  if [ -s /tmp/che ]; then
    echo "SQL Updated"
  else
    echo " "
    echo "Nothing to add"
    echo " "
  fi;
else
echo "You have the last release of ABillS DB"
fi;

rm -rf ${TMP_DIR}/dates ${TMP_DIR}/changes.sql ${TMP_DIR}/changes ${TMP_DIR}/che
}




#**********************************************
# Check modules version for update
# 
# Cards.pm
# Paysys.pm
# Ashield.pm
# Storage.pm
# Maps.pm
#**********************************************
check_modules () {


for module_name in Cards Paysys Ashield Maps Storage; do
  # echo "${module_name}";
  if [ -e ${BILLING_DIR}/Abills/mysql/${module_name}.pm ]; then 
    OLD=`cat ${BILLING_DIR}/Abills/mysql/${module_name}.pm |grep VERSION |sed 's/^[^0-9]*//;1d;s/;$//'`;
    NEW=`cat ${BILLING_DIR}/Abills/modules/${module_name}/webinterface |grep VERSION |sed 's/^[^0-9]*//;s/[^0-9]*$//'`

    if [ "${NEW}" = "" ]; then
      NEW=0
    fi;

    y=`echo "${NEW} * 100" |bc |cut -f1 -d "."`;

    OLD=`echo ${OLD} | tr -d '\b\r;'`
    if [ "${OLD}" = "" ]; then
      OLD=0
    fi;
    x=`echo "${OLD} * 100" |bc |cut -f1 -d "."`;
    
    if [ $x -lt $y ] > /dev/null 2>&1; then
      echo " "
      echo "!!! PLEASE UPDATE MODULE ${module_name} (the current version is ${NEW}) "
      echo " "
    fi;
  fi;
done

}


#**********************************************
#
#**********************************************
check_files () {

SYMFILE=paysys_check.cgi
REALFILE=../Abills/modules/Paysys/paysys_check.cgi
CGIBINDIR=${BILLING_DIR}/cgi-bin/

cd $CGIBINDIR

if [ -L ${SYMFILE} ]; then
  echo "Symlink file ${SYMFILE} OK"
else
  if [ -f ${SYMFILE} ]; then cp -f ${SYMFILE} ${SYMFILE}.bak; fi;
  ln -fs ${REALFILE} ${SYMFILE}
  echo "Ordinary file ${SYMFILE} replaced by symlink"
fi;

}

#**********************************************
# Check free space
# 
#**********************************************
check_free_space () {

if [ -d ${BILLING_DIR} ]; then
  abills_size=`du -s ${BILLING_DIR} |awk '{print $1}'`
else
  abills_size=0
fi;

ext_free_space=`expr ${abills_size} + 100000`

if [ x${OS} = xLinux ]; then 
  free_size=`df /usr | awk '{print $3}' |tail -1`
else 
  free_size=`df /usr | awk '{print $4}' |tail -1`
fi;

if [ "${free_size}" -le "${ext_free_space}" ]; then 
     echo " "
     echo !!! YOU HAVE NOT ENOUGH FREE SPACE ON /usr \( you have `df -h /usr | awk '{print $4}' |tail -1`, abills is `du -hs ${BILLING_DIR}` \)
     echo " "
     exit;
fi

}


#**********************************************
#
#**********************************************
beep () {
  for i in 3 2 1; do
    echo -e '\a\a';
    echo -n " Start update $i";
    sleep 1;
  done;
}

#**********************************************
# Help
#**********************************************
help () {
  echo "ABillS Updater Help";
  echo " Version ${VERSION}";
  
  echo " 
  -rollback [DATE]  - Rollback
  -win2utf          - Convert to UTF
  -amon             - Make AMon Checksum
  -full             - Make full Source update
  -speedy           - Replace perl to speedy
  -myisam2inodb     - Convert MyISAM table to InoDB
  -skip_tables      - Skip tables in converting
  -h,help,-help     - Help
  -debug            - Debug mode
  -clean            - Clean tmp files
  -v                - show version
  -prefix           - Prefix DIR
  -tmp              - Change tmp dir (Default: /tmp)
  -skip_backup      - Skip current system backup
  -skip_sql_update  - Skip SQL update
  -get_snapshot     - Update from snapshot system (Alternative way)
  -skip_update      - Skip check new version of updater
  -check_modules    - Check new version of modules 
  -skip_check_sql   - Skip check mysql version
  -m [MODULE]       - Update only modules
"
}


#**********************************************
# Convert MyISAM table to InoDB
#**********************************************
convert2inodb () {
  echo -n "DB host [localhost]: ";
  read db_host
  
  if [ "${db_host}" = "" ]; then
    db_host="localhost"
  fi;
  
  echo -n "DB user [root]: ";
  read db_user

  if [ "${db_user}" = "" ]; then
    db_user="root"
  fi;

  echo -n "DB password: ";
  read db_password

  echo -n "DB name [abills]: ";
  read db_name

  if [ "${db_name}" = "" ]; then
    db_name="abills"
  fi;

  if [ w${DEBUG} != w ]; then
    echo "db_host: ${db_host}";
    echo "db_user: ${db_user}";
    echo "db_password: ${db_password}";
    echo "db_name: ${db_name}";
  fi;
  
  TABLES=`${MYSQL} -h "${db_host}" -u "${db_user}" --password="${db_password}" -D ${db_name} -e "SHOW TABLES;"` 
  SKIP_TABLES=`echo ${SKIP_TABLES} | sed 's/\%/\.\*/g'`
  
  echo "SKIP_TABLES: ${SKIP_TABLES}"
  
  for table in ${TABLES} ; do
    TYPE=`${MYSQL} -h "${db_host}" -u "${db_user}" --password="${db_password}" -D ${db_name} -e "SHOW TABLE STATUS LIKE '${table}';" | tail -1 | awk '{ print \$2 }'` 
    IGNORE=""
    
    if [ "${TYPE}" = "InnoDB" ]; then
      echo " ${table} (${TYPE}) Already converted"
      IGNORE=1;
    fi;
  
    for IGNORE_TABLE in ${SKIP_TABLES}; do
      if [ x${table} = x${IGNORE_TABLE} ]; then
        IGNORE=1
      else
        RESULT=`echo ${table} | sed "s/${IGNORE_TABLE}/y/"`;
        if [ "${RESULT}" = y ]; then
          IGNORE=1
        fi;
      fi; 
    done
  
    if [ x${IGNORE} = x ]; then
      echo "Start convert: ${table}"
      query="alter table ${table} type=InnoDB;";
      res=`mysql -h "${db_host}" -u "${db_user}" --password="${db_password}" -D ${db_name} -e "${query};"`
      echo "${table} ${res}"
      if [ w${DEBUG} != w ]; then
        echo ${query};
      fi;
    else
      echo "Ignore"
    fi;
  done;             
}

#**********************************************
# Convert to UTF
#**********************************************
convert2utf () {
  ICONV="iconv";
  #BASE_CHARSET="cp1251";
  #OUTPUT_CHARSET="utf8";
  BASE_CHARSET="CP1251";
  OUTPUT_CHARSET="UTF-8";
    
  if [ w${OS} = wLinux ]; then
    COMMAND='iconv -f CP1251 -t UTF-8 {} -o {}.bak';
  else
    COMMAND='cat {} | iconv -f CP1251 -t UTF-8 > {}.bak';
  fi;

  action=$1;

  #Convert lang files
#  ${FIND} ${BILLING_DIR}/language -name "*.pl" -type f -exec ${ICONV}  -f ${BASE_CHARSET} -t ${OUTPUT_CHARSET} {} -o {}.bak `mv {}.bak {}` \;
  echo "Change lang file charset"
  for file in `ls ${BILLING_DIR}/language/*.pl` ${BILLING_DIR}/libexec/config.pl; do
    if [ w${OS} = wLinux ]; then
      ${ICONV}  -f ${BASE_CHARSET} -t ${OUTPUT_CHARSET} ${file} -o ${file}.bak
    else 
      cat ${file} | ${ICONV}  -f ${BASE_CHARSET} -t ${OUTPUT_CHARSET} > ${file}.bak
    fi;

    mv ${file}.bak ${file}
    sed "s/CHARSET='.*';/CHARSET='utf-8';/" ${file} > ${file}.bak
    mv ${file}.bak ${file}
    if [ x${DEBUG} != x ]; then
      echo ${file}
    fi;
  done
  
  echo "Convert modules lang files"
  ${FIND} ${BILLING_DIR} -name "lng*.pl" -type f -exec sh -c "${COMMAND}; mv {}.bak {}" \;

  echo "Conver template describe files"
  ${FIND} ${BILLING_DIR} -name "describe.tpls" -type f -exec sh -c "${COMMAND}; mv {}.bak {}" \;
  ${FIND} ${BILLING_DIR}/Abills/ -name "*.tpl" -type f -exec sh -c "${COMMAND}; mv {}.bak {}" \;
  #cat {} | ${ICONV} -f ${BASE_CHARSET} -t ${OUTPUT_CHARSET} > {}.bak `mv {}.bak {}` \;

  if [ w${action} = wupdate ]; then
    echo "Converted to UTF8";
  else 
    echo "Dictionary convertation finishing...";
    echo "Add to ${BILLING_DIR}/libexec/config.pl"
    echo ""
    echo "\$conf{dbcharset}='utf8';" 
    echo "\$conf{MAIL_CHARSET}='utf-8';" 
    echo "\$conf{default_language}='russian';" 
    echo "\$conf{default_charset}='utf-8';" 
  fi;
}


#**********************************************
# amon 
#**********************************************
amon () {
  echo "**********************************************************"
  echo "# ABillS AMon Update                                     #"
  echo "**********************************************************"
  FILENAME=${AMON};

  md5 ${FILENAME}
}


#**********************************************
# Speedy
#**********************************************
speedy () {
   SPEEDY="/usr/local/bin/speedy"
   SPEEDY_ARGS=" -- -r1";
   if [ ! -f ${SPEEDY} ]; then
     echo "speedy '${SPEEDY}' not found in system";
     exit;
   fi;

   #${FIND} ${BILLING_DIR} -type f -exec ${SED} -i '' -e "s,/usr/bin/perl,${SPEEDY},g" {} \;

   ${SED} -i '' -e "s,/usr/bin/perl,${SPEEDY}${SPEEDY_ARGS},g" "${BILLING_DIR}/cgi-bin/index.cgi"
   echo "Speedy Applied"
}

#**********************************************
# snapshot_update
#**********************************************
snapshot_update () {

  echo
  echo "**********************************************************"
  echo "# ABillS snapshot Update                                  #"
  echo "**********************************************************"


SNAPHOT_NAME=abills_.tgz
UPDATED=updated.txt
  
if [ w${OS} = wLinux ]; then
  wget -q -O ${TMP_DIR}/${UPDATED} "${SNAPHOT_URL}/${UPDATED}";
  wget -q -O ${TMP_DIR}/${SNAPHOT_NAME} "${SNAPHOT_URL}/${SNAPHOT_NAME}";
else 
  fetch -q -o ${TMP_DIR}/${UPDATED} "${SNAPHOT_URL}/${UPDATED}";
  fetch -q -o ${TMP_DIR}/${SNAPHOT_NAME} "${SNAPHOT_URL}/${SNAPHOT_NAME}";
fi;
  
  cat  ${TMP_DIR}/${UPDATED}

if [ ! -d ${TMP_DIR}/abills ]; then
  mkdir ${TMP_DIR}/abills
fi;
  
tar zxvf ${TMP_DIR}/${SNAPHOT_NAME} -C ${TMP_DIR}/abills
}


#**********************************************
# git_update
#**********************************************
git_update () {
  echo "Git Update";
  GIT=`which git`
  
  if [ "${GIT}" = "" ]; then
    echo "Install GIT"
    
    echo -n "Make autoinstall [y/n]: ";
    read AUTOINSTALL    
    if [ "${AUTOINSTALL}" != n ]; then
      if [ w${OS} = wLinux ]; then
        apt-get install git
      else 
        cd /usr/ports/devel/git && make install clean
      fi;
    fi;
  fi;

  if [ ! -f ~/.ssh/config ]; then
    echo "Please install auth key"
    echo -n "If you have auth key hit yes [y/n]:"
    read AUTH_KEY_PRESENT;
    if [ "${AUTH_KEY_PRESENT}" != n ]; then
      echo -n "Enter path to auth key: ";
      read AUTH_KEY
      echo -n "Enter auth login: ";
      read AUTH_USER
      if [ -f "${AUTH_KEY}" ]; then 
        echo "${AUTH_KEY} ~/.ssh/id_dsa.${AUTH_USER}"
        cp "${AUTH_KEY}" ~/.ssh/id_dsa.${AUTH_USER}
        chmod 400 ~/.ssh/id_dsa.${AUTH_USER}
        echo "Host abills.net.ua
         User ${AUTH_USER}
         Hostname abills.net.ua
         IdentityFile ~/.ssh/id_dsa.${AUTH_USER}" >> ~/.ssh/config
      else
        echo "Wrong key '${AUTH_KEY}' ";
        exit;
      fi;
    fi;  
    
  else
    CHECK_KEY=`grep abills.net.ua ~/.ssh/config`;
    if [ "${CHECK_KEY}" = "" ]; then
      echo "You don't have update key"
      echo "Contact ABillS Suppot Team"
      exit;
    fi;
  fi;


  if [ -d "${TMP_DIR}/abills" ]; then 
    CHECK_CVS=`find ${TMP_DIR}/abills | grep CVS`
    if [ "${CHECK_CVS}" != "" ]; then
      rm -rf ${TMP_DIR}/abills*;
    fi;
  fi;


  if [ -d "${TMP_DIR}/abills" ]; then
    cd ${TMP_DIR}/abills
    ${GIT} pull
    cd ..
  else 
    #Git repository
    ${GIT} clone git@abills.net.ua:abills.git
  fi;
  
}

#**********************************************
# Speedy
#**********************************************
rollback () {
  echo "Rollback"
}


# Proccess command-line options
#
for _switch ; do
        case $_switch in
        -debug)
                DEBUG=1;
                echo "Debug enable"
                shift; 
                ;;
        -v)
                echo "Version: ${VERSION}";
                exit;
                ;;
        -amon)  
                AMON=$1;
                shift; shift
                ;;
        -full)   FULL=1;
                shift; shift
                ;;
        -speedy) SPEEDY=1;
                shift; shift
                ;;           
        -h)     HELP=1;
                ;;
        -help)  HELP=1;
                ;;
        help)   HELP=1;
                ;;
        -clean) CLEAN=1;
                shift; shift
                ;;
        -rollback) ROLLBACK=$1
                shift; shift
                ;;
        -prefix) BILLING_DIR=$2
                shift; shift
                ;;
        -win2utf) CONVERT2UTF=1
                shift;
                ;;
        -tmp)   TMP_DIR=$2
                shift; shift
                ;;
        -myisam2inodb) INODB=1;
                shift; 
                ;;
        -skip_tables) SKIP_TABLES=$2;
                shift; shift;
                ;;
        -info)  SYS_INFO=1;
                shift; 
                ;;
        -m)     UPDATE_MODULE=$2
                shift; shift;
                ;;
        -skip_backup) SKIP_BACKUP=1
                shift;
                ;;
        -skip_sql_update)  SKIP_SQL_UPDATE=1
                shift;
                ;;
        -skip_update) SKIP_UPDATE=1
                shift;
                ;;
        -git) GIT_UPDATE=1
                shift;
                ;;
        -get_snapshot) GET_SNAPSHOT=1
                shift;
                ;;
        -check_modules) CHECK_MODULES=1
                shift;
                ;;
        -skip_check_sql) SKIP_CHECK_SQL=1
                shift;
                ;;        
        -reg)   REGISTRATION=1;
                shift;
        esac
done

update_self

if [ w${HELP} != w ] ; then
  help;
  exit;
fi;

if [ w${CONVERT2UTF} != w ] ; then
  convert2utf;
  exit;
fi;

if [ w${AMON} != w ] ; then
  amon ${AMON};
fi;

if [ w${INODB} != w ] ; then
  convert2inodb;
  exit;
fi;

if [ x"${REGISTRATION}" !=  x ]; then
  sys_info;
  exit;
elif [ x"${SYS_INFO}" != x ] ; then
  sys_info;
  exit;
fi;

if [ x{CHECK_MODULES} != x ]; then
  check_modules;
fi;

if [ w${ROLLBACK} != w ] ; then
  rollback ${ROLLBACK};
else 
  echo "**********************************************************"
  echo "# ABillS Update                                          #"
  echo "**********************************************************"

  #show errors
  if [ -f  /var/log/httpd/abills-error.log ]; then
    echo "Web errors";
    tail /var/log/httpd/abills-error.log
    echo "**********************************************************"
  fi;

  check_free_space
  
  if [ -f "${BILLING_DIR}/libexec/config.pl" ]; then
    CURE_CHARSET=`cat ${BILLING_DIR}/libexec/config.pl | grep dbcharset  | sed "s/^\\$conf{dbcharset}='\(.*\)';/\1/"`;
  
    if [ x"${CURE_CHARSET}" = xcp1251 ]; then
      echo "First convert to UTF8";
      echo "see manual: "
      echo " http://abills.net.ua/forum/viewtopic.php?f=1&t=5795"      
      exit;
    fi;
  fi;


  if [ -d ${BILLING_DIR} ]; then
    if [ w${SKIP_SQL_UPDATE} = w ]; then
      update_sql
    fi;

    if [ -d ${BILLING_DIR}_${DATE} ]; then
      SKIP_BACKUP=1
      echo "Skiping backup. Today backup exist"
    fi;

    #Backup curent version
    if [ w${SKIP_BACKUP} = w ]; then
      if [ -d ${BILLING_DIR} ]; then
        cp -Rf ${BILLING_DIR} ${BILLING_DIR}_${DATE}
        echo "Backuped to '${BILLING_DIR}_${DATE}'. Please wait some minutes" 
      else
        echo " '${BILLING_DIR}' Not exist. Created ${BILLING_DIR}  "
        mkdir ${BILLING_DIR}
      fi;


      if [ -f ${BILLING_DIR}/libexec/updated ]; then
        echo "Last Updated".
        UPDATED=`cat ${BILLING_DIR}/libexec/updated`;
        echo ${UPDATED};
        LAST_UPDATED=`echo ${UPDATED} | awk '{ print $1 }'`
      fi;

      cp -Rf ${BILLING_DIR} ${BILLING_DIR}_${DATE}
     else 
       echo "Skip backup...";
     fi;

    if [ w${FULL} != w ]; then
       echo "Make full source update";
       rm -rf ${TMP_DIR}/abills*
    fi;
  else
    mkdir ${BILLING_DIR}
  fi;

  beep;
  echo ""

  cd ${TMP_DIR}  
  #Update from snapshots
  # http://abills.net.ua/snapshots/
  if [ x${GET_SNAPSHOT} != x ]; then
    snapshot_update

  #Git update
  elif [ x${GIT_UPDATE} != x ]; then
    git_update;
  #Update from CVS
  else 
    echo
    CVS=`which cvs`;
    if [ "${CVS}" = "" ]; then
      echo "Update program 'cvs' not found."
      echo "Please install cvs"
      exit;
    fi;
   
    ${CVS} -d:pserver:anonymous:@abills.cvs.sourceforge.net:/cvsroot/abills login > /dev/null 2>&1 
    ${CVS} -z3 -d:pserver:anonymous@abills.cvs.sourceforge.net:/cvsroot/abills checkout -r ${REL_VERSION} abills
  fi;
  
  cd  ${TMP_DIR}
  echo "${DATE} DATE: ${FULL_DATE} UPDATE by ABILLS update" > ${TMP_DIR}/abills/libexec/updated;
  work_copy="abills_rel"

  if [ ! -d ${work_copy} ]; then
    mkdir ${work_copy}
    echo "Make '${work_copy}'"
  fi;

  cp -Rf abills/* ${work_copy}/

  find ${work_copy} | grep CVS | xargs rm -Rf
  find ${work_copy} | grep .git | xargs rm -Rf  

  for dir in "${work_copy}/var" "${work_copy}/var/log" "${work_copy}/var/q" "${work_copy}/var/log/ipn"; do
    if [ ! -d ${dir} ]; then
      mkdir ${dir};
    fi;
  done;
  
  if [ w${UPDATE_MODULE} != w ]; then
    if [ w${DEBUG} != w ] ; then
      echo "cp -Rf ${TMP_DIR}/${work_copy}/Abills/modules/${UPDATE_MODULE}/* ${BILLING_DIR}/Abills/modules/${UPDATE_MODULE}/"
    fi;

    cp -Rf ${TMP_DIR}/${work_copy}/Abills/modules/${UPDATE_MODULE}/* ${BILLING_DIR}/Abills/modules/${UPDATE_MODULE}/
    if [ -f ${TMP_DIR}/${work_copy}/Abills/mysql/${UPDATE_MODULE}.pm ]; then
      cp ${TMP_DIR}/${work_copy}/Abills/mysql/${UPDATE_MODULE}.pm ${BILLING_DIR}/Abills/mysql/
    fi;

    echo "Modules '${UPDATE_MODULE}' updated";
  else
    if [ w${DEBUG} != w ] ; then
      echo "cp -Rf ${TMP_DIR}/${work_copy}/* ${BILLING_DIR}"
    fi;

    cp -Rf ${TMP_DIR}/${work_copy}/* ${BILLING_DIR}
    #Update Version 
    if [ -f  ${BILLING_DIR}/libexec/config.pl ]; then
      OLD_VERSION=`cat ${BILLING_DIR}/libexec/config.pl | grep versi | ${SED} "s/\\$conf{version}='\([0-9]*\)\.\([0-9]*\).*'.*/\1\2/"`

      if [ ${OLD_VERSION} -lt 61 ]; then
        NEW_VERSION=`cat ${BILLING_DIR}/libexec/config.pl.default | grep versi | ${SED} "s/\\$conf{version}='\(.*\)'.*/\1/"`
      else
        NEW_VERSION=0.61
      fi;

      cp ${BILLING_DIR}/libexec/config.pl ${BILLING_DIR}/libexec/config.pl.bak
      ${SED} "s/\$conf{version}='.*'/\$conf{version}='${NEW_VERSION}\/${DATE}'/" ${BILLING_DIR}/libexec/config.pl > ${BILLING_DIR}/libexec/config.pl.new
      mv ${BILLING_DIR}/libexec/config.pl.new ${BILLING_DIR}/libexec/config.pl
      echo "Config updated";

      #convert to utf-8
#      if [ w != w`grep "$conf{dbcharset}='utf8'" ${BILLING_DIR}/libexec/config.pl` ]; then
#        convert2utf update 
#      fi;

      #Freebsd radius Restart
      if [ -x /usr/local/etc/rc.d/radiusd ]; then
        /usr/local/etc/rc.d/radiusd restart
        echo "RADIUS restarted"
      #Ubuntu radius restart
      elif [ -x /etc/init.d/freeradius  ]; then    
        /etc/init.d/freeradius restart
        echo "RADIUS restarted"
      fi;
    fi;
  fi;

  check_modules;
  check_files;
  echo "Done.";
fi;

if [ w${CLEAN} != w ] ; then
  rm -rf ${TMP_DIR}/abills*;
fi;

if [ w${SPEEDY} != w ] ; then
  speedy;
fi;


