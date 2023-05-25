#!/bin/bash

set -o errexit -o noclobber -o nounset -o pipefail # Safe defaults..

LC_ALL=C
LANG=C
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export LC_ALL LANG PATH

SWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die () {
	local rc=$1
	shift
	[ -z "$@" ] || echo "${BASH_SOURCE[1]}:${BASH_LINENO[0]} => " "$@" >&2
	exit $rc
}

setup_server () {
	[ -z "$SIGNSERVER_NODEID" ] && die 1 "Missing SIGNSERVER_NODEID environment variable.."
	[ -d /data/db ] || mkdir -p /data/db
	pushd /opt/jboss/wildfly/standalone > /dev/null
	rm -f log
	mkdir -p /data/logs
	ln -s /data/logs log
	popd > /dev/null
}

setup_pkcs11 () {
	[ "${CRYPTOSERVER:-}" != "" ] || die 2 "Missing CRYPTOSERVER env variable."
	sed -i'' -e "s|CRYPTOSERVER|${CRYPTOSERVER}|" /opt/utimaco/p11/libcs_pkcs11_R3.cfg
	sed -i'' -e "s/CS_PKCS11_LOGLEVEL/${CS_PKCS11_LOGLEVEL:-3}/" /opt/utimaco/p11/libcs_pkcs11_R3.cfg
	sed -i'' -e "s/CS_PKCS11_KEEPALIVE/${CS_PKCS11_KEEPALIVE:-true}/" /opt/utimaco/p11/libcs_pkcs11_R3.cfg
	sed -i'' -e "s/CS_PKCS11_MULTISESSION/${CS_PKCS11_MULTISESSION:-false}/" /opt/utimaco/p11/libcs_pkcs11_R3.cfg
	sed -i'' -e "s/CS_PKCS11_SLOTCOUNT/${CS_PKCS11_SLOTCOUNT:-25}/" /opt/utimaco/p11/libcs_pkcs11_R3.cfg
	export CS_PKCS11_R3_CFG=/opt/utimaco/p11/libcs_pkcs11_R3.cfg
	sed -i'' -e "s|CRYPTOSERVER|${CRYPTOSERVER}|" /opt/utimaco/p11/libcs_pkcs11_R2.cfg
	sed -i'' -e "s/CS_PKCS11_LOGLEVEL/${CS_PKCS11_LOGLEVEL:-3}/" /opt/utimaco/p11/libcs_pkcs11_R2.cfg
	sed -i'' -e "s/^KeepAlive = .*$/KeepAlive = ${CS_PKCS11_KEEPALIVE:-true}/" /opt/utimaco/p11/libcs_pkcs11_R2.cfg
	sed -i'' -e "s/^SlotMultiSession = .*$/SlotMultiSession = ${CS_PKCS11_KEEPALIVE:-false}/" /opt/utimaco/p11/libcs_pkcs11_R2.cfg
	export CS_PKCS11_R2_CFG=/opt/utimaco/p11/libcs_pkcs11_R2.cfg
}

declare -r CMD="${1:-}"
shift || :

case "${CMD}" in
  server)
	setup_pkcs11
	setup_server
	exec /opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 "$@"
	;;
  shell)
	setup_pkcs11
	exec /bin/bash "$@"
	;;
  '')
	die 254 "Unknown command (available commands: server, shell)"
	;;
  *)
	die 255 "Invalid command: ${CMD}"
	;;
esac

exit $?

# vim: ai ts=4 sw=4 noet sts=4 ft=sh
