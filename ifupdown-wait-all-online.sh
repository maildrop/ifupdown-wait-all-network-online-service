#!/bin/sh
set -e 

PATH=/usr/bin:/bin
ADDTIONAL_DEVICES="tun0 tun1 tun2"
WITHOUT_INET4_DEVICE=""
WITHOUT_INET6_DEVICE="tun0 tun1 tun2"

[ -f /etc/default/networking ] && . /etc/default/networking

status=true;
for timeout in 0 3 12 15 30 60 60; do 
    status=true;
    for dev in $(/sbin/ifquery --list -X lo -X '*:*') ${ADDTIONAL_DEVICES} ; do
        ipdev=$(/usr/sbin/ip -oneline link show | /usr/bin/awk '{sub(/(@.*)?:$/ ,"", $2); print $2;}' )
        if [ -z "$(echo $ipdev | grep $dev)" ] ; then
            # device not found
            status=false;
        else
            if [ -z "$(echo ${WITHOUT_INET4_DEVICE} | grep ${dev})" ] ; then
                if [ -z "$(/usr/sbin/ip -family inet -oneline address show dev $dev scope global)" ] ; then
                    status=false;
                fi
                
            fi
            if [ -z "$(echo ${WITHOUT_INET6_DEVICE} | grep ${dev})" ] ; then
                if [ -z "$(/usr/sbin/ip -family inet6 -oneline address show dev $dev scope global)" ] ; then
                    status=false;
                fi

                # DAD check
                # @see https://serverfault.com/questions/638442/lighttpd-does-not-start-at-boot-after-enabling-ipv6
                for attempt in $(seq 1 10); do
                    if [ -z "$(/usr/sbin/ip -family inet6 -oneline address show dev $dev scope global tentative)" ] ; then
                        break;
                    fi
                    /usr/bin/sleep 0.3
                done

                if [ -n "$(/usr/sbin/ip -family inet6 -oneline address show dev $dev scope global tentative)" ] ; then
                    status=false;
                fi
                
            fi
        fi
    done
    /usr/bin/sleep ${timeout};
    if [ "${status}" = "true" ] ; then
        break;
    fi
done

if [ "${status}" = "true" ] ; then
    return 0
else
    return 1
fi

