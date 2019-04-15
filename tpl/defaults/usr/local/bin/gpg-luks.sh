#!/bin/bash

function fatal()
{
	echo "FATAL: $@" >&2
	exit
}

mount=1

while getopts "uk:d:" opt; do
	case $opt in
		u)
			mount=0
			;;
		k)
			key=$OPTARG
			;;
		d)
			device=$OPTARG
			;;
	esac
done

id=$(echo $device | openssl sha1 | tr -d '(stdin)= ')

export DISPLAY=:0
export XAUTHORITY=/home/dimitri/.Xauthority
export PINENTRY_USER_DATA=qt
export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus'
export UDISKS_SYSTEM=0

if [[ $mount -eq 1 ]]
then
	if [[ ! -f $key ]]
	then
		fatal "The speified key does not exist"
	fi

	sudo -u dimitri --preserve-env=DBUS_SESSION_BUS_ADDRESS,DISPLAY,XAUTHORITY,PINENTRY_USER_DATA,UDISKS_SYSTEM gpg -d "$key" 2>/dev/null | cryptsetup -v --key-file=- luksOpen "/dev/$device" "$id"
else
	umount "/dev/mapper/$id"
	cryptsetup luksClose "$id"
fi

