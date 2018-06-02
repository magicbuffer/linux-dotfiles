#!/bin/sh

echo "$2"
echo "$2"

if [ ! -f "$1" ]
then
	echo "#ffffff"
	exit
fi

pid=$(cat "$1")
ps -p "$pid" > /dev/null 2>&1
if [ $? -eq 0 ]
then
	echo "#00ff7f"
else
	echo "#ffffff"
fi
