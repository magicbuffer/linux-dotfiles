#!/bin/bash

if [[ ! -f "$1" ]]
then
	echo "'$1' is  not a file" >&2
	exit
fi

sign-file sha512 "pkcs11:model=eToken;manufacturer=SafeNet%2c%20Inc.;serial=02617759;token=d%40magicbuffer.net;id=%3d%eb%92%9c%04%33%95%43%53%6a%49%d7%a1%f4%11%6f%9b%27%62%0f;" "$1"
