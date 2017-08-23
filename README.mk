Run ./install.sh for setup

you may need to configure the location of iptables and ip6tables in fw-lib.sh 
if you are not using debian stretch with bash

place your firewall scripts with executeable permissions in /etc/fw_rules.d

Example: 

--------------------------------------------------
#!/usr/lib/fw-lib.sh
require RULE-FILE-IN-ETC-FW_RULES.D
iptables -N SOMECHAIN
iptables -I SOMECHAIN -j ACCEPT 
ip6tables -I INPUT -j REJECT
-------------------------------------------------

