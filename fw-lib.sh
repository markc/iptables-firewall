#!/bin/bash
# this one is used as bang within a firewall ruleset. 

export FW_CFG_PATH="/etc/fw_rules.d"
export IPTABLES="/sbin/iptables"
export IP6TABLES="/sbin/ip6tables"
export EBTABLES="/sbin/ebtables"
export FW_SCRIPT="${1}"
export FLAG_PATH="${2}"
export FLAG_PATH_CREATED="false"

if [[ ! -e "${FW_SCRIPT}" ]]
then
	cat << EOF
This is a wrapper around *tables scripts (iptables, ip6tables, ebtables)
It can be used as a shell scripts by "#!/usr/bin/env fw_lib.sh" or 
It needs at least one parameter, which needs to be an existing file,
to work, which does not exists. 

Have a look at /etc/fw_rules.d and the iptables-firewall framework for 
more info
EOF
	exit 1
fi

if [[ -z "${FLAG_PATH}" ]] || [[ -d "${FLAG_PATH}" ]]
then
	umask 077
	FLAG_PATH=$(/bin/mktemp -d /tmp/firewall_flags.XXXXXXXX)
	FLAG_PATH_CREATED="true"
fi

if [[ ! -z "${FLAG_PATH}" ]] && [[ -d "${FLAG_PATH}" ]]
then
	FLAG=$(systemd-escape -p "${1#./}")
	if [[ -f "${FLAG_PATH}/${FLAG}.run" ]]
	then
		echo "${FLAG} already loaded to Kernel, skip"
		exit 0
	else
		touch "${FLAG_PATH}/${FLAG}.run" 
	fi
fi

check_ipt() {
	IPTCMD="${1}"
	shift
	TBL_PARM="-t"
	TBL="filter"
	if [[ "${1}" = "-t" ]]
	then
		shift
		TBL="${1}"
		shift
	fi
	COMMAND="${1}"
	shift
	CHAIN="${1}"
	shift
	case "${COMMAND}" in
		-X)
			TEST_COMMAND="-L"
		;;
		-N)
			TEST_COMMAND="-L"
			INVERT_RET="true"
		;;
		-D)
			TEST_COMMAND="-C"
		;;
		*)
			TEST_COMMAND="-C"
			INVERT_RET="true"
		;;
	esac
	"${IPTCMD}" "${TBL_PARM}" "${TBL}" "${TEST_COMMAND}" "${CHAIN}" "${@}" 2> /dev/null > /dev/null
	RET="$?"
	if [[ "${INVERT_RET}" = "true" ]]
	then
		if [[ "${RET}" = 0 ]]
		then
			return 1
		fi
		return 0
	fi
	return ${RET}
}

require_ipt() {
	if check_ipt "${@}"
	then
		${@}
	fi
}

check_ebt() {
	EBTCMD="${1}"
	shift
	TBL_PARM="-t"
	TBL="filter"
	if [[ "${1}" = "-t" ]]
	then
		shift
		TBL="${1}"
		shift
	fi
	COMMAND="${1}"
	shift
	CHAIN="${1}"
	shift
	case "${COMMAND}" in
		-X)
			TEST_COMMAND="-L"
		;;
		-N)
			TEST_COMMAND="-L"
			INVERT_RET="true"
		;;
		-D)
			TEST_COMMAND="-I"
		;;
		-F)
			return 0
			# we can always flush
		;;
		*)
			TEST_COMMAND="-I"
			INVERT_RET="true"
		;;
	esac
	if [[ "${TEST_COMMAND}" == "-I" ]]
	then
		# this is going to be more complex because ebtables does not provide -C checks
		# basicly it ads a custom chain which then adds the command to recreate what 
		# it would look like in ebtables. Then it greps for that command
		"${EBTABLES}" "${TBL_PARM}" "${TBL}" -N GET_EBT_FMT_$$
		"${EBTABLES}" "${TBL_PARM}" "${TBL}" "-F" GET_EBT_FMT_$$
		"${EBTABLES}" "${TBL_PARM}" "${TBL}" "-I" GET_EBT_FMT_$$ "${@}"
		GREPSTR=$("${EBTABLES}" "${TBL_PARM}" "${TBL}" "-L" GET_EBT_FMT_$$ --Lx)
		"${EBTABLES}" "${TBL_PARM}" "${TBL}" -X GET_EBT_FMT_$$
		GREPSTR="${GREPSTR/GET_EBT_FMT_$$/${CHAIN}}"
		"${EBTABLES}" "${TBL_PARM}" "${TBL}" "-L" "${CHAIN}" --Lx | grep -F -x "${GREPSTR}" 2> /dev/null > /dev/null
		RET="$?"
	else
		"${EBTABLES}" "${TBL_PARM}" "${TBL}" "${TEST_COMMAND}" "${CHAIN}" "${@}" 2> /dev/null > /dev/null
		RET="$?"
	fi
	if [[ "${INVERT_RET}" = "true" ]]
	then
		if [[ "${RET}" = 0 ]]
		then
			return 1
		fi
		return 0
	fi
	return ${RET}
}

require_ebt() {
	if check_ebt "${@}"
	then
		${@}
	fi
}

iptables() {
	require_ipt "${IPTABLES}" "${@}"
}

ip4t() {
	require_ipt "${IPTABLES}" "${@}"
}

ip6tables() {
	require_ipt "${IP6TABLES}" "${@}"
}

ip6t() {
	require_ipt "${IP6TABLES}" "${@}"
}

ebtables() {
	require_ebt "${EBTABLES}" "${@}"
}

ebt() {
	require_ebt "${EBTABLES}" "${@}"
}

require() {
	"${FW_CFG_PATH}/${1}" "${FLAG_PATH}"
}

# load actual rules to kernel
. "${@}"

if [[ "${FLAG_PATH_CREATED}" = "true" ]]
then
	# we may have to clean up our mess
	/bin/rm -f "${FLAG_PATH}/"*.run
	/bin/rmdir "${FLAG_PATH}" || echo "Warning: Supressing Errorcode $?"
fi
