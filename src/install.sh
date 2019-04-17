#!/bin/bash
#
# DotFiles installer
#

if [[ $UID != 0 ]]
then
	sudo $0 $@
	exit
fi

here=$(realpath $(dirname "$0"))
debug=1

function installer_debug()
{
	[ -n "$debug" ] && echo "DEBUG : $@" >&2
}

function installer_info()
{
	echo "INFO    : $@" >&2
}

function installer_warning()
{
	echo "WARNING : $@" >&2
}

function installer_fatal()
{
	echo "FATAL   : $@" >&2
	exit -1
}

function installer_execute()
{
	installer_debug "$@"
	[[ -n $debug ]] && $@
}

function sha1()
{
	[[ ! -f "$1" ]] && return -1
	openssl sha1 "$1" | awk '{print $2}'
}

function installer_update_template_permissions()
{
	[[ ! -d $1 ]] && installer_fatal "'$1' is not a valid directory"

	for element in $(find "$template" -mindepth 1 -not -name ".gitignore")
	do
		target="${element//$template/}"
		if [[ ! -e $target ]]
		then
			installer_warning "The element '$element' is not installed"
			continue
		fi

		target_owner=$(stat -c "%U:%G" "$target")
		target_perm=$(stat -c "%a" "$target")

		if [[ -z $target_owner ]]
		then
			installer_warning "Failed to retrieve '$element' ownership"
		else
			echo "$target_owner" > "$element.owner"
		fi

		if [[ -z $target_perm ]]
		then
			installer_warning "Failed to retrieve '$element' permissions"
		else
			 echo "$target_perm"  > "$element.perm"
		fi
	done
}

function installer_set_installation_ownership()
{
	local element=$1
	local target=$2
	local element_owner_file="$(dirname $element)/.$(basename $element).owner"

	if [[ ! -e $target ]]
	then
		installer_warning "Missing installation element '$target'"
		return
	fi
	if [[ ! -f $element_owner_file ]]
	then
		installer_warning "Missing ownership information for template element '$element'"
		return
	fi

	local target_owner=$(stat -c "%U:%G" "$target")
	local template_owner=$(cat "$element_owner_file")

	if [[ -z $template_owner || -z $target_owner ]]
	then
		installer_warning "Unable to retrieve ownership information for template element '$element'"
	else
		if [[ $target_owner != $template_owner ]]
		then
			installer_info "Setting ownership for installation element '$element'"
			[[   -L $target ]] && installer_execute chown -h "$template_owner" "$target"
			[[ ! -L $target ]] && installer_execute chown    "$template_owner" "$target"
		fi
	fi
}

function installer_set_installation_permission()
{
	local element=$1
	local target=$2
	local element_perm_file="$(dirname $element)/.$(basename $element).perm"

	if [[ ! -e $target ]]
	then
		installer_warning "Missing installation element '$target'"
		return
	fi
	if [[ ! -f $element_perm_file ]]
	then
		installer_warning "Missing permission information for template element '$element'"
		return
	fi

	local target_perm=$(stat -c "%a" "$target")
	local template_perm=$(cat "$element_perm_file")

	if [[ -z $template_perm || -z $target_perm ]]
	then
		installer_warning "Unable to retrieve permission information for template element '$element'"
	else
		if [[ $target_perm != $template_perm ]]
		then
			installer_info "Setting permission for installation element '$element'"
			installer_execute chmod "$template_perm" "$target"
		fi
	fi
}

function installer_install_directory()
{
	local target=$1

	[[ -d $target ]] && return
	if [[ -e $target ]]
	then
		installer_warning "Installation directory '$target' exists but is not a directory"
		return
	fi

	installer_execute mkdir -p "$target"
}

function installer_install_file()
{
	local element=$1
	local target=$2

	if [[ ! -f $element ]]
	then
		installer_warning "Template element '$element' is not a file"
		return
	fi
	if [[ -f $target ]]
	then
		local element_hash=$(sha1 "$element")
		local target_hash=$(sha1 "$target")
		[[ $element_hash == $target_hash ]] && return
	else
		if [[ -e $target ]]
		then	
			installer_warning "Installation file '$target' exists but is not a file"
			return
		fi
	fi

	installer_execute cp "$element" "$target"
}

function installer_install_symlink()
{
	local element=$1
	local target=$2

	if [[ ! -L $element ]]
	then
		installer_warning "Template element '$element' is not a symlink"
	fi

	local element_target=$(readlink "$element")

	if [[ -L $target ]]
	then
		local target_target=$(readlink "$target")
		[[ $element_target == $target_target ]] && return
	else
		if [[ -e $target ]]
		then
			installer_warning "Installation symlink '$target' exists but is not a symlink"
			return
		fi
	fi

	pushd $(dirname "$element") >/dev/null

	installer_execute rm -f "$target"
	installer_execute ln -s "$element_target" "$target"

	popd >/dev/null
}

function installer_install_element()
{
	local element=$1
	local target=$2

	if [[ -z $element ]]
	then
		installer_warning "Missing installation element"
		return
	fi
	if [[ -z $target ]]
	then
		installer_warning "Missing installation target"
		return
	fi

	if [[ -d "$element" ]]
	then
		installer_install_directory "$target"
		return
	fi
	if [[ -L "$element" ]]
	then
		installer_install_symlink "$element" "$target"
		return
	fi
	if [[ -f "$element" ]]
	then
		installer_install_file "$element" "$target"
		return
	fi

}

function installer_update_installation()
{
	local template=$1

	[[ ! -d $template ]] && installer_fatal "'$1' is not a valid directory"

	for element in $(find "$template" -mindepth 1 -not -name "*.owner" -not -name "*.perm" -not -name ".gitignore")
	do
		local target="${element//$template/}"
		installer_install_element "$element" "$target"
		installer_set_installation_ownership "$element" "$target"
		installer_set_installation_permission "$element" "$target"
	done
}

function installer_update_template()
{
	local template=$1

	[[ ! -d $template ]] && installer_fatal "'$1' is not a valid directory"

	for element in $(find "$template" -mindepth 1 -not -name "*.owner" -not -name "*.perm" -not -name ".gitignore")
	do
		local target="${element/$template/}"

		if [[ ! -e $target ]]
		then
			installer_warning "The installation element does not exists '$target'"
			continue
		fi

		local target_owner=$(stat -c "%U:%G" "$target")
		local target_perm=$(stat -c "%a" "$target")

		local target_owner_file="$(dirname $element)/.$(basename $element).owner"
		local target_perm_file="$(dirname $element)/.$(basename $element).perm"

		echo "$target_owner" > "$target_owner_file"
		echo "$target_perm"  > "$target_perm_file"

		installer_execute chown $SUDO_USER:$(id -g $SUDO_USER) "$target_owner_file"
		installer_execute chown $SUDO_USER:$(id -g $SUDO_USER) "$target_perm_file"
	
		if [[ -f $element ]]
		then
			file_hash=$(sha1 "$element")
			target_hash=$(sha1 "$target")

			#installer_debug "file_hash   : '$file_hash'"
			#installer_debug "target_hash : '$target_hash'"

			[[ $file_hash == $target_hash ]] && continue

			installer_execute cp "$target" "$element"
			installer_execute chown $SUDO_USER:$(id -g $SUDO_USER) "$element"
		fi
	done
}

function installer_usage()
{
	echo "Usage: $0 [-t template] [-u installation|template]" >&2
	exit 1
}

function installer_install_blackarch()
{
	local bootstrapper=$(mktemp)

	curl -o "$bootstrapper" 'https://blackarch.org/strap.sh'
	local hash=$(sha1 "$bootstrapper")
	
	if [[ $hash != '9f770789df3b7803105e5fbc19212889674cd503' ]]
	then
		installer_fatal "Invalid sha1 hash for blackarch bootstrapper 'strap.sh'"
	fi

	sh "$bootstrapper"
}

function installer_install_yay()
{
	local directory=$(mktemp -d)

	pushd "$directory"

	git clone 'https://aur.archlinux.org/yay.git' .
	makepkg -si

	popd
}

function installer_install_packages()
{
	local packages=

	while read -r package
	do
		[[ ${package:0:1} == '#' ]] && continue
		[[ ${package:0:1} == ''  ]] && continue

		local packages="$packages $package"
	done < "$here/../pkg"

	yay -Sy "$packages"
}

update="installation"

while getopts "t:u:" o
do
	case "${o}" in
		t)
			template=${OPTARG}
			;;
		u)
			update=${OPTARG}
			;;
		*)
			installer_usage
			;;
	esac
done

if [[ -z $template ]]
then
	# Get the machine ID
	[[ ! -f "/etc/machine-id" ]] && installer_fatal "Unknown machine"
	machine_id=$(cat "/etc/machine-id")
	[[ -z "$machine_id" ]] && installer_fatal "Unknown machine" || installer_info "Detected machine '$machine_id'"
fi

template="$here/../tpl/defaults"
template_override="$here/../tpl/$machine_id"

[[ ! -d "$template" ]] && installer_fatal "template not found"

case "$update" in
	installation)
		installer_update_installation "$template"
		installer_update_installation "$template_override"
		;;
	template)
		installer_update_template "$template"
		installer_update_template "$template_override"
		;;
	packages)
		installer_install_yay
		installer_install_blackarch
		installer_install_packages
		;;
	*)
		installer_fatal "Unknown update mode '$update'"
esac
