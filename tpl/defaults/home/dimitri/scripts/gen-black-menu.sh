#!/bin/bash

function fatal()
{
	echo "FATAL: $@" >&2
	exit -1
}

function info()
{
	echo "INFO: $@"
}

function bashify()
{
	echo "$@" | sed 's/-/_/g'
}

function unbashify()
{
	echo "$@" | sed 's/_/-/g'
}

function load_db()
{
	local db=$1

	if [[ ! -f $db ]]
	then
		info "The database file does not exist '$db'."
		build_db "$db"
	fi

	if [[ ! -f "$db" ]]
	then
		fatal "Failed to build the database at '$db'"
	fi

	info "Loading the database at '$db'"
	source "$db"
}

function update_db()
{
	local db=$1
	local db_dir=$(dirname "$db")

	# If the db directory does not exist create it
	mkdir -p "$db_dir"

	## If the db exists drop it
	#if [[ -f $db ]]
	#then
	#	info "Backing up the database at '$db'"
	#	mv "$db" "$db.bak"
	#fi

	# Get the package list from the repo and iterate over it
	while read -r p
	do
		echo "$p" | cut --delimiter=" " -f 3- | grep blackarch >/dev/null 2>&1
		if [[ $? -gt 0 ]]
		then
			continue
		fi

		pkg_name=$(echo "$p" | cut --delimiter=" " -f 1 | cut -c 11-)
		pkg_version=$(echo "$p" | cut --delimiter=" " -f 2)
		pkg_groups=$(echo "$p" | cut --delimiter=" " -f 3- | sed 's/^.//g' | sed 's/ \[installed*]//g' | sed 's/.$//g')

		info "$pkg_name"

		if [[ -z $pkg_groups || $groups == installed ]]
		then
			continue
		fi
		
		#echo -n "$pkg_name;$pkg_version;"
		for g in $pkg_groups
		do
			if [[ $g == blackarch ]]
			then
				continue
			fi

			mkdir -p "$db_dir/$g"
			touch "$db_dir/$g/$pkg_name"

			## Store the group pkg_name for latter use
			#groups="$groups\n$g"
			## Compute the group's variable pkg_name
			#v="$(bashify $g)"
			## Acquire the old group members
			#old="$(eval echo \$$v)"
			## Compute the new group members
			#new="$old $pkg_name"
			## Store the new group members
			#eval "$v='$new'"
		done
	done < <(yaourt -S -l blackarch)
	
	# Sort out the groups
	groups=$(echo -e "$groups" | sort -u)
	
	## Store the group
	#echo -n "groups=(" > "$db"
	#for g in $groups
	#do
	#	info "Discovered group '$g'"
	#	echo -n "$(bashify $g) " >> "$db"
	#done
	#echo ")" >> "$db"
	## Store all the groups members
	#for g in $groups
	#do
	#	echo -n "$(bashify $g)=(" >> "$db"
	#	echo -n $(eval echo \$$(bashify $g)) >> "$db"
	#	echo ")" >> "$db"
	#done
}

function print_groups()
{
	local db=$1
	local i=0
	local output=
	#for group in "${groups[@]}"
	for group in $(find "$db" -mindepth 1 -type d | sort)
	do
		output="$output;[$(printf %02d $i)] $(echo $(basename $group) | sed 's/blackarch-//g')"
		((i=i+1))

		if [ $((i%4)) -eq 0 ]
		then
			output="$output\n"
		fi
	done
	echo -e "$output" | column -t -s ";" -c $(tput cols) -W 1,2,3,4
}

function print_group_members()
{
	local node=$1
	local i=0
	local output=

	#for member in $(eval echo '${'$1'[@]}')
	for member in $(find "$node" -type f | sort)
	do
		output="$output;[$(printf %02d $i)] $(basename $member)"
		((i=i+1))

		if [ $((i%4)) -eq 0 ]
		then
			output="$output\n"
		fi
	done
	echo number of columns $(tput cols)
	echo -e "$output" | column -t -s ";" -c $(tput cols) -W 1,2,3,4
}

echo '    __    __           __                              '
echo '   / /_  / /___ ______/ /______ ___  ___  ____  __  __ '
echo '  / __ \/ / __ `/ ___/ //_/ __ `__ \/ _ \/ __ \/ / / / '
echo ' / /_/ / / /_/ / /__/ ,< / / / / / /  __/ / / / /_/ /  '
echo '/_.___/_/\__,_/\___/_/|_/_/ /_/ /_/\___/_/ /_/\__,_/   '
echo

db="$HOME/.cache/blackmenu"
if [[ ! -d "$db" ]]
then
	update_db "$db"
fi

echo "$(find "$db" -type f -exec basename {} \; | sort -u | wc -l) tools in the database!" 

echo 'Available groups:'
print_groups "$db"

while true
do
	read -p "Command: " choice

	case "$choice" in
	'q'|'quit'|'exit'|'bye')
		exit
		;;
	'l'|'list')
		print_groups "$db"
		continue
		;;
	'h'|'help'|'?'|*)
		re='^[0-9]+$'
		if [[ $choice =~ $re ]]
		then
			found=0
			i=0
			for group in $(find "$db" -mindepth 1 -type d | sort)
			do
				if [[ $choice -eq $i ]]
				then
					info "printing group members '$(basename $group)'"
					print_group_members "$db/$(basename $group)"
					found=1
					break
				fi
				((i=i+1))
			done

			if [[ $found -le 0 ]]
			then
				echo "group '$choice' not found"
			fi
		else
			echo "available commands: [q|quit|exit|bye] exit blackmenu"
			echo "                    [l|list]          print groups"
			echo "                    [0-999]           print group member"
		fi
		continue
		;;
	esac

done
