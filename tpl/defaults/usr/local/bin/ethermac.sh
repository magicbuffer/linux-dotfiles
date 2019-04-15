#!/bin/bash
# Data source: https://regauth.standards.ieee.org/standards-ra-web/pub/view.html#registries

debug=1
name=macspoofer
database=oui.db
config_dirs="$HOME/.config/$name
$HOME/.$name
/etc/$name"

function debug()
{
	if [[ ! -z $debug ]]
	then
		echo "DEBUG : $@" >&2
	fi
}

function info()
{
	echo "INFO  : $@"
}

function error()
{
	echo "ERROR : $@" >&2
	exit -1
}

function execute()
{
	if [[ ! -z $debug ]]
	then
		debug $@
	fi
	eval $@
	if [[ $? -ne 0 ]]
	then
		error "Failed to execute '$@'"
	fi
}

function sql()
{
	execute sqlite3 "$database_path" "\"$1\"" 
}

function initialize_database()
{
	sql "create table organization(id int primary key, name varchar(250) collate nocase)"
	sql "create table assignment(value varchar(6) primary key collate nocase, fk_organization int)"
	
	OLDIFS=$IFS
	IFS=","

	while read reg mac name address
	do
		exist=$(sql "select rowid from assignment where value = '$mac' collate nocase")
		if [[ -n $exist ]]
		then
			continue
		fi

		name=$(echo $name | tr -d "\"'")
		org=$(sql "select rowid from organization where name = '$name' collate nocase")
		if [[ -z $org ]]
		then
			sql "insert into organization (name) values('$name')"
			org=$(sql "select rowid from organization where name = '$name' collate nocase")
		fi
		if [[ -z $org ]]
		then
			echo "Failed to insert org '$name'" >&2
			continue
		fi

		echo $mac:$name
		sql "insert into assignment values('$mac', '$org')"
	done < "$1"

	IFS=$OLDIFS
}

function get_mac_random()
{
	random=$(sql 'select value,fk_organization from assignment order by random() limit 1')

	OLDIFS=$IFS
	IFS="|"
	
	while read mac organization_id
	do
		echo $mac
		#org=$(sql "select name from organization where rowid = '$organization_id'")
	done <<< "$random"

	IFS=$OLDIFS
}

function get_mac_by_name()
{
	org_rowid=$(sql "select rowid from organization where name = '$1' collate nocase")
	sql "select value from assignment where fk_organization = '$org_rowid'" | while read mac
	do
		echo $mac
	done
}

function get_organization_by_mac()
{
	oui=$(echo "$1" | tr -d :)
	oui=${oui:0:6}

	org_rowid=$(sql "select fk_organization from assignment where value = '$oui' collate nocase")
	if [[ -z $org_rowid ]]
	then
		error "The OUI '$oui' is not present in the database."
	fi

	org_name=$(sql "select name from organization where rowid = '$org_rowid'")
	echo $org_name
}

function get_organizations()
{
	sql "select name from organization order by name" | while read org
	do
		echo $org
	done
}

function get_random_byte()
{
	dd if=/dev/random bs=1 count=1 2>/dev/null | xxd -p
}

function build_mac()
{
	b1=$(get_random_byte)
	b2=$(get_random_byte)
	b3=$(get_random_byte)
	echo ${1:0:2}:${1:2:2}:${1:4:2}:$b1:$b2:$b3
}

function set_mac_iproute2()
{
	interface="$1"
	mac="$2"

	execute $elevator ip link set dev "$interface" down
	execute $elevator ip link set dev "$interface" address "$mac"
	execute $elevator ip link set dev "$interface" up

	info "Setted MAC address '$mac' on interface '$interface'"
}

function set_mac()
{
	interface="$1"
	mac="$2"

	if [[ -z $interface ]]
	then
		error "No interface selected"
	fi
	if [[ -z $mac ]]
	then
		error "Cannot set a null MAC"
	fi

	ip=$(ip -V)
	case "$ip" in
		*iproute2*)
			set_mac_iproute2 "$interface" "$mac"
			return
			;;
	esac

	error "I don't know how to set the mac"
}

# Database scanning
for config_dir in $config_dirs
do
	debug "Scanning : $config_dir"
	if [[ ! -d $config_dir ]]
	then
		debug "Diretory does not exist"
		continue
	fi
	if [[ -f $config_dir/$database ]]
	then
		debug "Database found"
		database_path=$config_dir/$database
		break
	fi
done
if [[ -z $database_path ]]
then
	error "$name database not found"
fi

# Elevator detection
if [[ $UID -ne 0 ]]
then
version_sudo=$(sudo --version)
case $version_sudo in
sudo*|Sudo*)
    elevator=sudo
    ;;
*)
    elevator=su -c 
    ;;
esac
fi

# Getopt
TEMP=$(getopt -l init: -l db: -l interface: -l assign: -l assign-random -l assign-by-name: -l list-organizations -l search-by-name: -l search-by-mac: -- +i:rn: "$@")
eval set -- "$TEMP"

while test "X$1" != "X--"
do
    case "$1" in
	--init)
		shift
		datasource="$1"
		mode=init
		;;
	--db)
		shift
		database_path="$1"
		;;
	-i|--interface)
		shift
		interface="$1"
		;;
	--assign)
		shift
		mode=assign
		mac="$1"
		;;
        -r|--assign-random)
		mode=assign-random
		;;
        -n|--assign-by-name)
		shift
		mode=assign-by-name
		name="$1"
		;;
        --search-by-name)
		shift
		mode=search-by-name
		name="$1"
		;;
	--search-by-mac)
		shift
		mode=search-by-mac
		mac="$1"
		;;
	--list-organizations)
		mode=list-organizations
		;;
        *)
		error "Unrecognized option '$1'"
		;;
    esac 
    shift
done

if [[ -z $mode ]]
then
	error "Unspecified operation mode"
fi
case "$mode" in
	init)
		;;
	assign)
		if [[ -z $interface ]]
		then
			error "No interface specified"
		fi
		if [[ -z $mac ]]
		then
			error "No MAC specified"
		fi
		set_mac "$interface" "$mac"
		;;
	assign-random)
		if [[ -z $interface ]]
		then
			error "No interface specified"
		fi
		org=$(get_mac_random)
		mac=$(build_mac "$org")
		set_mac "$interface" "$mac"
		;;
	assign-by-name)
		if [[ -z $interface ]]
		then
			error "No interface specified"
		fi
		if [[ -z $name ]]
		then
			error "No organization name specified"
		fi
		org=$(get_mac_by_name "$name")
		mac=$(build_mac "$org")
		set_mac "$interface" "$mac"
		;;
	search-by-name)
		get_mac_by_name "$name"
		;;
	search-by-mac)
		get_organization_by_mac "$mac"
		;;
	list-organizations)
		get_organizations
		;;
esac
