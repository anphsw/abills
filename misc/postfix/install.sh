#!/bin/sh
# Make vmail user account

if [ -x /usr/sbin/nologin ]; then
        NOLOGIN=/usr/sbin/nologin
else
        NOLOGIN=/sbin/nologin
fi

if [ x"$1" = xADD_VMAIL_USER ]; then
        USER=vmail
        UID=1005
        GROUP=vmail
        GID=1005

        if /usr/sbin/pw groupshow "${GROUP}" 2>/dev/null; then
                echo "You already have a group \"${GROUP}\", so I will use it."
        else
                if /usr/sbin/pw groupadd ${GROUP} -g ${GID}; then
                        echo "Added group \"${GROUP}\"."
                else
                        echo "Adding group \"${GROUP}\" failed..."
                        echo "Please create it, and try again."
                        exit 1
                fi
        fi


        if /usr/sbin/pw user show "${USER}" 2>/dev/null; then
                echo "You already have a user \"${USER}\", so I will use it."
        else
                if /usr/sbin/pw useradd ${USER} -u ${UID} -g ${GROUP} -h - -d /var/spool/virtual/ -s ${NOLOGIN} -c "vMail System"; then
                        echo "Added user \"${USER}\"."
                else
                        echo "Adding user \"${USER}\" failed..."
                        echo "Please create it, and try again."
                        exit 1
                fi
        fi

fi;


