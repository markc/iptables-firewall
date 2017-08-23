#!/bin/bash
install  -m "0755" -o root -g root firewall.service /etc/systemd/system/firewall.service
install  -m "0755" -o root -g root fw-lib.sh /usr/lib/fw-lib.sh
install  -m "0755" -o root -g root fw-load.sh /usr/sbin/fw-load.sh
install -m "0700" -o root -g root -d /etc/fw_rules.d
