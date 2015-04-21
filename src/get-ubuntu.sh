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
	echo "help info..."
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

function wgetProgressFilter () {
    local flag=false c count cr=$'\r' nl=$'\n'
    while IFS='' read -d '' -rn 1 c
    do
        if $flag
        then
            printf '%c' "$c"
        else
            if [[ $c != $cr && $c != $nl ]]
            then
                count=0
            else
                ((count++))
                if ((count > 1))
                then
                    flag=true
                fi
            fi
        fi
    done
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
#URL="http://p1.pichost.me/i/74/1984455.jpg"
DONE=1

while [ "$DONE" != "0" ]; do
	echo -n "$( date +'%Y-%m-%d %X' ) Tentativo di download..."
	wget -q --spider "$URL"
	DONE="$?"
	if [ "$DONE" == "0" ]; then
		echo "OK"
		wget --progress=bar:force "$URL" 2>&1 | wgetProgressFilter
		echo "$( date +'%Y-%m-%d %X' ) Download terminato"
	else
		echo "FAIL"
		echo "$( date +'%Y-%m-%d %X' ) Nessuna release. Ritento tra $WAIT"
		sleep "$WAIT"
	fi
done

exit 0