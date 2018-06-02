#!/bin/sh

this=$(realpath "$0")

function cleanup()
{
	for f in "$@"
	do
		[[ ! -f $f ]] && continue
		shred --remove --zero "$f" || return $?
	done
}

if [[ $1 == "cleanup" ]]
then
	shift
	cleanup "$@"
fi
if [[ $1 == "start" ]]
then
	shift

	[[ -z $1 ]] && exit -1
	[[ -z $2 ]] && exit -1
	[[ -z $3 ]] && exit -1
	
	provider=$1
    country=$2
    protocol=$3
    
    config_dir="$HOME/.config/openvpn/$provider"
	[[ ! -d $config_dir ]] && exit -1

	# Create the config file
    config=$(mktemp)
    [[ ! -f $config ]] && exit -1

	# Pick the desired entry
	unset found
	while IFS=';' read -r _country _protocol _server _port _ping_speed _ping_exit _mtu _fragment _mssfix
	do
		if [[ $country == $_country && $protocol == $_protocol ]]
		then
			echo "proto $protocol"          >> "$config"
			echo "remote $_server" "$_port" >> "$config"
			echo "ping $_ping_speed"        >> "$config"
			echo "ping-exit $_ping_exit"    >> "$config"

			if [ "$protocol" == "udp" ]
			then
				echo "tun-mtu $_mtu"       >> "$config"
				echo "fragment $_fragment" >> "$config"
				echo "mssfix $mssfix"      >> "$config"
			fi

			found=1
			break
		fi
	done < "$config_dir/endpoints"
	# Oups, invalid country and/or protocol
	[[ -z $found ]] && cleanup "$config" && exit -1

	# Boilerplate settings
	echo "client"                 >> "$config"
    echo "dev tun"                >> "$config"
    echo "auth-nocache"           >> "$config"
    echo "resolv-retry infinite"  >> "$config"
    echo "redirect-gateway def1"  >> "$config"
    echo "persist-key"            >> "$config"
    echo "persist-tun"            >> "$config"
    echo "nobind"                 >> "$config"
    echo "cipher AES-256-CBC"     >> "$config"
    echo "auth SHA512"            >> "$config"
    echo "ping-timer-rem"         >> "$config"
    echo "remote-cert-tls server" >> "$config"
    echo "route-delay 5"          >> "$config"
    echo "verb 4"                 >> "$config"
    echo "comp-lzo"               >> "$config"
	echo "remap-usr1 SIGTERM"     >> "$config"
	echo "writepid /run/openvpn.pid" >> "$config"

	# Setup needed files
    auth_file=$(mktemp)
    auth_cert=$(mktemp)
    auth_key=$(mktemp)
    auth_ca=$(mktemp)
    
	[[ ! -f $auth_file ]] && cleanup "$config" "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" && exit -1
    [[ ! -f $auth_cert ]] && cleanup "$config" "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" && exit -1
    [[ ! -f $auth_key  ]] && cleanup "$config" "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" && exit -1
	[[ ! -f $auth_ca   ]] && cleanup "$config" "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" && exit -1

	# Finalize the config file
    echo "auth-user-pass $auth_file" >> "$config"
    echo "ca   $auth_ca"             >> "$config"
    echo "cert $auth_cert"           >> "$config"
    echo "key  $auth_key"            >> "$config"
    
    # Install post connection hook
    echo "script-security 2" >> "$config"
    echo "up   \"$this cleanup '$auth_file' '$auth_cert' '$auth_key' '$auth_ca' '$config'\"" >> "$config"
    echo "down \"$this cleanup '$auth_file' '$auth_cert' '$auth_key' '$auth_ca' '$config'\"" >> "$config"

	# Finally decrypt the auth and pki stuff
	gpg --yes --decrypt --output "$auth_file" "$config_dir/credentials.asc" || ( cleanup "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" "$config" && exit -1 )
	gpg --yes --decrypt --output "$auth_cert" "$config_dir/client.cer.asc"  || ( cleanup "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" "$config" && exit -1 )
	gpg --yes --decrypt --output "$auth_key"  "$config_dir/client.key.asc"  || ( cleanup "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" "$config" && exit -1 )
	gpg --yes --decrypt --output "$auth_ca"   "$config_dir/ca.cer.asc"      || ( cleanup "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" "$config" && exit -1 )
    
    # Fire
    sudo -- openvpn "$config"
	cleanup "$auth_file" "$auth_cert" "$auth_key" "$auth_ca" "$config"
fi
