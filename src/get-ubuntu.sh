#!/bin/bash

NAME="get-ubuntu"
VERSION="1.0"
AUTHOR="Mirco Bertelli"

OPTIONS="t:a:r:w:vh"

ARCH=""
TYPE=""
RELEASE=""
WAIT=""

URL_BASE="http://releases.ubuntu.com"

function help () {
    local NORM="\e[0m"
    local BOLD="\e[1m"
    local ULIN="\e[4m"

	echo -e "${BOLD}NAME${NORM}"
    echo -e "    $NAME - download ubuntu iso.\n"

    echo -e "${BOLD}SYNOPSIS${NORM}"
    echo -e "    $NAME [${ULIN}options${NORM}]\n"

    echo -e "${BOLD}DESCRIPTION${NORM}"
    echo -e "    This tool ping Canonical's servers to get Ubuntu ISO as soon as possible.\n"

    echo -e "${BOLD}OPTIONS${NORM}"
    echo -e "    ${BOLD}-h${NORM}"
    echo -e "        Showes this user manual.\n"

    echo -e "    ${BOLD}-v${NORM}"
    echo -e "        Showes info about versio and author.\n"

    echo -e "    ${BOLD}-a${NORM} ${ULIN}ARCH${NORM}"
    echo -e "        Specifies the desiderated arch (32 or 64 bits) of the iso to download."
    echo -e "        Valid values for ${ULIN}ARCH${NORM} are '32' or '64'.\n"

    echo -e "    ${BOLD}-t${NORM} ${ULIN}TYPE${NORM}"
    echo -e "        Specifies the type of the distro desiderated (server or desktop)."
    echo -e "        Valid values for ${ULIN}TYPE${NORM} are 'desktop' (or 'd') or 'server' (or 's').\n"

    echo -e "    ${BOLD}-r${NORM} ${ULIN}RELEASE_CODE${NORM}"
    echo -e "        Specifies the version of the desiderated ubuntu iso."
    echo -e "        ${ULIN}RELEASE_CODE${NORM} must be a value like 14.04, 14.10, 12.10, ...\n"

    echo -e "    ${BOLD}-w${NORM} ${ULIN}WAIT_TIME${NORM}"
    echo -e "        Specifies the amount of time to wait between two download attempts."
    echo -e "        ${ULIN}WAIT_TIME${NORM} must have this format ${ULIN}NUMBER${NORM}[${ULIN}SUFFIX${NORM}]."
    echo -e "        ${ULIN}SUFFIX${NORM} should be 's', 'm', 'h', 'd' to specify seconds, minutes, hours"
    echo -e "        or days. If there is not ${ULIN}SUFFIX${NORM}, it uses ${ULIN}NUMBER${NORM} as seconds.\n"
	exit 0
}

function version () {
	echo -e "$NAME v$VERSION\n$AUTHOR"
	exit 0
}

function setArch () {
	case "$1" in
		32) ARCH="i386"  ;;
		64) ARCH="amd64" ;;
		 *) echo "Achitettura non valida" >&2; exit 1 ;;
	esac
}

function setType () {
	case "$1" in
		desktop | d) TYPE="desktop"  ;;
		server  | s) TYPE="server" ;;
		 *) echo "Tipo non valido" >&2; exit 1 ;;
	esac
}

function setRelease () {
	local regex="^[0-9]{2}\.[0-9]{2}$"
	if [[ "$1" =~ $regex ]]; then
		 RELEASE="$1"
	else
		echo "Release non valida" >&2
		exit 1
	fi
}

function setWaitingTime () {
	local regex="^[1-9]+[smh]$"
	if [[ "$1" =~ $regex ]]; then
		WAIT="$1"
	else
		echo "Intervallo di tempo non valido" >&2
		exit 1
	fi
}

function getLocalArch () {
	local arch="$( uname -m )"
	case $arch in
		x86_64) echo "amd64";;
		x86)    echo "i386";;
		*) echo "$arch: architettura non supportata." >&2; exit 1 ;;
	esac
}

function getCurrentRelease () {
	local year="$( date +%y )"
	local month="$( date +%m )"
	if (( month < 4 )); then
		month="10"
		year="$(( year - 1 ))"
	elif (( month < 10 )); then
		month="04"
	else
		month="10"
	fi
	echo "$year.$month"
}

function getDefaultWaitingTime () {
	echo "15m"
}

function fillEmptyOptions () {
	if [ -z $TYPE ]; then
		TYPE="desktop"
	fi
	if [ -z $ARCH ]; then
		ARCH="$( getLocalArch )"
	fi
	if [ -z $RELEASE ]; then
		RELEASE="$( getCurrentRelease )"
	fi
	if [ -z $WAIT ]; then
		WAIT="$( getDefaultWaitingTime )"
	fi
}

function testRemoteFileExist () {
    local url=$1
    local httpCode="$(curl -s --head "$url" | grep -e ^HTTP  | sed -r 's/^.*([[:digit:]]{3}).*$/\1/g')"
    if [ "$httpCode" = "200" ]; then
        return "0"
    else
        return "1"
    fi
}

while getopts ":$OPTIONS" opt; do
	case $opt in
		h)
			help
		;;
		v)
			version
		;;
		t)
			setType "$OPTARG"
		;;
		a)
			setArch "$OPTARG"
		;;
		r)
			setRelease "$OPTARG"
		;;
		w)
			setWaitingTime "$OPTARG"
		;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
		;;
	esac
done

fillEmptyOptions
URL="$URL_BASE/$RELEASE/ubuntu-$RELEASE-$TYPE-$ARCH.iso"
DONE=1

while [ "$DONE" != "0" ]; do
	echo -n "$( date +'%Y-%m-%d %X' ) Tentativo di download... "
	testRemoteFileExist "$URL"
	DONE="$?"
	if [ "$DONE" == "0" ]; then
		echo "OK"
        curl -# "$URL" -O
		echo "$( date +'%Y-%m-%d %X' ) Download terminato"
	else
		echo "FAIL"
		echo "$( date +'%Y-%m-%d %X' ) Nessuna release. Ritento tra $WAIT"
		sleep "$WAIT"
	fi
done

exit 0