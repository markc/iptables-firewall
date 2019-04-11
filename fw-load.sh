#!/bin/bash
# loads the all rules in /etc/fw_rules.d into the kernel
export FW_CFG_PATH="/etc/fw_rules.d"
export FLAG_PATH=""
export FLAG_PATH_CREATED="false"

case "${1}" in
	stop)
		for tbl in filter nat raw mangle security
		do
			iptables -t "${tbl}" -F 
			iptables -t "${tbl}" -X 
		done
		for tbl in filter nat broute
		do
			ebtables -t "${tbl}" -F 
			ebtables -t "${tbl}" -X 
		done
	;;
	start|reload|*)

		/bin/run-parts "${FW_CFG_PATH}"
		# on debian based oses we can use --args to set a fixed 
		# run path on our tokens. unfortunately centos and redhat have a 
		# shellscript there missing that particular part
		# we may provide a better run-parts in the future but for now
		# this code is commented out
		#
		# if [[ -z "${FLAG_PATH}" ]] || [[ -d "${FLAG_PATH}" ]]
		# then
		# 	umask 077
		# 	FLAG_PATH=$(/bin/mktemp -d /tmp/firewall_flags.XXXXXXXX)
		# 	FLAG_PATH_CREATED="true"
		# fi
		# /bin/run-parts "--arg=${FLAG_PATH}" "${FW_CFG_PATH}"
		# if [[ "${FLAG_PATH_CREATED}" = "true" ]]
		# then
		# 	# we may have to clean up our mess
		# 	/bin/rm -f "${FLAG_PATH}/"*.run
		# 	/bin/rmdir "${FLAG_PATH}"
		# fi
	;;
esac
