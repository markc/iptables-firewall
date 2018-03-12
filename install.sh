#!/bin/bash
PREFIX=${PREFIX:-}
INSTDIR=${INSTDIR:-/usr/local}
echo $PREFIX$INSTDIR
exit 
install -d ${PREFIX}${INSTDIR}/share
install -d ${PREFIX}${INSTDIR}/sbin
install  -m "0755" -o root -g root firewall.service ${PREFIX}/etc/systemd/system/firewall.service
install  -m "0755" -o root -g root fw-lib.sh ${PREFIX}${INSTDIR}/share/fw-lib.sh
install  -m "0755" -o root -g root fw-load.sh ${PREFIX}${INSTDIR}/sbin/fw-load.sh
install -m "0700" -o root -g root -d ${PREFIX}/etc/fw_rules.d
systemctl daemon-reload
echo $?
systemctl enable firewall
echo $?
systemctl start firewall
echo $?
exit 0
